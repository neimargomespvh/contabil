import { Building2, FileText, Receipt, Calculator, TrendingUp, AlertCircle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { useAuthStore } from '@/stores/auth.store';

interface StatCardProps {
  title: string;
  value: string;
  icon: React.ElementType;
  color: string;
  hint?: string;
}

function StatCard({ title, value, icon: Icon, color, hint }: StatCardProps) {
  return (
    <Card>
      <CardContent className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className="mt-1 text-2xl font-bold text-gray-900">{value}</p>
          {hint && <p className="mt-1 text-xs text-gray-400">{hint}</p>}
        </div>
        <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
      </CardContent>
    </Card>
  );
}

export function DashboardPage() {
  const user = useAuthStore((s) => s.user);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Bem-vindo de volta, {user?.nome}!
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Empresas"
          value="—"
          icon={Building2}
          color="bg-brand-600"
          hint="Clientes do escritório"
        />
        <StatCard
          title="Lançamentos"
          value="—"
          icon={FileText}
          color="bg-emerald-600"
          hint="Mês atual"
        />
        <StatCard
          title="Documentos"
          value="—"
          icon={Receipt}
          color="bg-amber-600"
          hint="Pendentes de contabilização"
        />
        <StatCard
          title="Apurações"
          value="—"
          icon={Calculator}
          color="bg-purple-600"
          hint="A vencer este mês"
        />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100">
                <TrendingUp className="h-5 w-5 text-emerald-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Começando agora</h3>
                <p className="text-sm text-gray-500">
                  Cadastre sua primeira empresa para começar
                </p>
              </div>
            </div>
            <div className="mt-4 space-y-2 text-sm text-gray-600">
              <p>✓ API rodando em <code className="rounded bg-gray-100 px-1">localhost:3000</code></p>
              <p>✓ Frontend em <code className="rounded bg-gray-100 px-1">localhost:5173</code></p>
              <p>✓ Autenticação funcionando</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
                <AlertCircle className="h-5 w-5 text-amber-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Próximos passos</h3>
                <p className="text-sm text-gray-500">
                  Módulos que serão ativados nas próximas entregas
                </p>
              </div>
            </div>
            <ul className="mt-4 space-y-2 text-sm text-gray-600">
              <li>• Cadastro de empresas e sócios</li>
              <li>• Plano de contas e lançamentos</li>
              <li>• Importação de XML e conciliação</li>
              <li>• Apurações e relatórios</li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
