import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Layout } from '@/components/Layout';
import { ProtectedRoute } from '@/components/ProtectedRoute';
import { ToastContainer } from '@/components/ui/Toast';
import { LoginPage } from '@/pages/Login';
import { EmpresasListPage } from '@/pages/empresas/EmpresasList';
import { LancamentosListPage } from '@/pages/lancamentos/LancamentosList';
import { LancamentoDetailPage } from '@/pages/lancamentos/LancamentoDetail';
import { PlanoContasPage } from '@/pages/plano-contas/PlanoContas';
import { DocumentosFiscaisPage } from '@/pages/documentos-fiscais/DocumentosFiscais';
import { RegrasContabilizacaoPage } from '@/pages/regras-contabilizacao/RegrasContabilizacao';

import { EmpresaDetailPage } from '@/pages/empresas/EmpresaDetail';

import { DashboardPage } from '@/pages/Dashboard';
import { NotFoundPage } from '@/pages/NotFound';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 1000 * 60 * 5, // 5 min
    },
  },
});

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          <Route element={<ProtectedRoute />}>
            <Route element={<Layout />}>
              <Route index element={<DashboardPage />} />

              {/* Rotas que virão nos próximos pacotes */}
              <Route path="empresas" element={<EmpresasListPage />} />
              <Route path="empresas/:id" element={<EmpresaDetailPage />} />
              <Route path="plano-contas" element={<PlanoContasPage />} />
              <Route path="lancamentos" element={<LancamentosListPage />} />
              <Route path="lancamentos/:id" element={<LancamentoDetailPage />} />
              <Route path="documentos-fiscais" element={<DocumentosFiscaisPage />} />
              <Route path="regras-contabilizacao" element={<RegrasContabilizacaoPage />} />
              <Route path="conciliacao" element={<EmBreve titulo="Conciliação" />} />
              <Route path="apuracoes" element={<EmBreve titulo="Apurações" />} />
              <Route path="relatorios" element={<EmBreve titulo="Relatórios" />} />
              <Route path="usuarios" element={<EmBreve titulo="Usuários" />} />
              <Route path="perfis" element={<EmBreve titulo="Perfis" />} />
              <Route path="perfil" element={<EmBreve titulo="Meu Perfil" />} />

              <Route path="*" element={<NotFoundPage />} />
            </Route>
          </Route>

          <Route path="/404" element={<NotFoundPage />} />
          <Route path="*" element={<Navigate to="/404" replace />} />
        </Routes>
      </BrowserRouter>
      <ToastContainer />
    </QueryClientProvider>
  );
}

function EmBreve({ titulo }: { titulo: string }) {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center">
      <div className="rounded-lg border-2 border-dashed border-gray-300 bg-white p-12 text-center">
        <p className="text-4xl">🚧</p>
        <h2 className="mt-4 text-xl font-semibold text-gray-900">{titulo}</h2>
        <p className="mt-2 text-sm text-gray-500">
          Este módulo será implementado na próxima entrega.
        </p>
      </div>
    </div>
  );
}
