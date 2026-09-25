import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

export const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
});

// ─────────────────────────────────────────────────────
// REQUEST — injeta o token automaticamente
// ─────────────────────────────────────────────────────
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('@contabil:token');
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ─────────────────────────────────────────────────────
// HELPER — desembrulha { success, data, timestamp } → data
// ─────────────────────────────────────────────────────
function unwrap<T = any>(body: any): T {
  if (
    body &&
    typeof body === 'object' &&
    !Array.isArray(body) &&
    'success' in body &&
    'data' in body &&
    ('timestamp' in body || 'statusCode' in body)
  ) {
    return body.data as T;
  }
  return body as T;
}

// ─────────────────────────────────────────────────────
// RESPONSE — refresh 401 + desembrulho
// ─────────────────────────────────────────────────────
let isRefreshing = false;
let failedQueue: Array<{ resolve: (v: any) => void; reject: (e: any) => void }> = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((p) => (error ? p.reject(error) : p.resolve(token)));
  failedQueue = [];
};

api.interceptors.response.use(
  (response) => {
    // Nunca desembrulhar downloads binários
    if (
      response.config.responseType === 'blob' ||
      response.config.responseType === 'arraybuffer'
    ) {
      return response;
    }

    response.data = unwrap(response.data);
    return response;
  },
  async (error) => {
    const original = error.config;

    if (
      error.response?.status === 401 &&
      !original._retry &&
      !original.url?.includes('/auth/')
    ) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((token) => {
          original.headers.Authorization = `Bearer ${token}`;
          return api(original);
        });
      }

      original._retry = true;
      isRefreshing = true;

      const refreshToken = localStorage.getItem('@contabil:refreshToken');
      if (!refreshToken) {
        localStorage.clear();
        window.location.href = '/login';
        return Promise.reject(error);
      }

      try {
        // axios "cru" — o interceptor global NÃO se aplica a esta chamada,
        // por isso desembrulhamos manualmente.
        const refreshResponse = await axios.post(
          `${API_URL}/auth/refresh`,
          { refreshToken },
        );
        const { accessToken } = unwrap<{ accessToken: string }>(
          refreshResponse.data,
        );

        localStorage.setItem('@contabil:token', accessToken);
        api.defaults.headers.Authorization = `Bearer ${accessToken}`;
        processQueue(null, accessToken);
        original.headers.Authorization = `Bearer ${accessToken}`;
        return api(original);
      } catch (refreshError) {
        processQueue(refreshError, null);
        localStorage.clear();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  },
);

// ─────────────────────────────────────────────────────
// Helper para extrair mensagem amigável de erro
// ─────────────────────────────────────────────────────
export function getApiError(error: any): string {
  const body = error?.response?.data;

  if (body?.message) {
    const msg = body.message;
    return Array.isArray(msg) ? msg.join(', ') : msg;
  }
  if (body?.error) return body.error;
  if (error?.message) return error.message;
  return 'Erro inesperado';
}