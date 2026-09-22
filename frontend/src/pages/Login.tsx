import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Building2 } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { toast } from '@/components/ui/Toast';
import { authService } from '@/services/auth.service';
import { useAuthStore } from '@/stores/auth.store';
import { getApiError } from '@/lib/axios';

const schema = z.object({
  email: z.string().email('Email inválido'),
  senha: z.string().min(6, 'Senha deve ter pelo menos 6 caracteres'),
});

type FormData = z.infer<typeof schema>;

export function LoginPage() {
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      const response = await authService.login(data.email, data.senha);
      setAuth(response.user, response.accessToken, response.refreshToken);
      toast.success(`Bem-vindo, ${response.user.nome}!`);
      navigate('/', { replace: true });
    } catch (error) {
      toast.error(getApiError(error));
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-50 to-gray-100 p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-brand-600 text-white shadow-lg">
            <Building2 className="h-8 w-8" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Sistema Contábil</h1>
          <p className="mt-1 text-sm text-gray-500">Entre com suas credenciais</p>
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="seu@email.com"
                autoComplete="email"
                {...register('email')}
                error={errors.email?.message}
              />
            </div>

            <div>
              <Label htmlFor="senha">Senha</Label>
              <Input
                id="senha"
                type="password"
                placeholder="••••••••"
                autoComplete="current-password"
                {...register('senha')}
                error={errors.senha?.message}
              />
            </div>

            <Button type="submit" className="w-full" loading={isSubmitting} size="lg">
              Entrar
            </Button>
          </form>
        </div>

        <p className="mt-6 text-center text-xs text-gray-500">
          © {new Date().getFullYear()} Sistema Contábil — Todos os direitos reservados
        </p>
      </div>
    </div>
  );
}
