import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard, Building2, BookOpen, FileText, Receipt,
  Landmark, Calculator, BarChart3, Users, Shield, Settings, X,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuthStore } from '@/stores/auth.store';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

const NAV_ITEMS = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, permission: null },
  { to: '/empresas', label: 'Empresas', icon: Building2, permission: 'empresa.ver' },
  { to: '/plano-contas', label: 'Plano de Contas', icon: BookOpen, permission: 'plano.ver' },
  { to: '/lancamentos', label: 'Lançamentos', icon: FileText, permission: 'lancamento.ver' },
  { to: '/documentos-fiscais', label: 'Documentos Fiscais', icon: Receipt, permission: 'documento.ver' },
  { to: '/conciliacao', label: 'Conciliação', icon: Landmark, permission: 'conciliacao.ver' },
  { to: '/apuracoes', label: 'Apurações', icon: Calculator, permission: 'apuracao.ver' },
  { to: '/relatorios', label: 'Relatórios', icon: BarChart3, permission: 'relatorio.ver' },
];

const ADMIN_ITEMS = [
  { to: '/usuarios', label: 'Usuários', icon: Users, permission: 'usuario.ver' },
  { to: '/perfis', label: 'Perfis', icon: Shield, permission: 'role.ver' },
];

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const hasPermission = useAuthStore((s) => s.hasPermission);

  const renderItems = (items: typeof NAV_ITEMS) =>
    items
      .filter((item) => !item.permission || hasPermission(item.permission))
      .map((item) => {
        const Icon = item.icon;
        return (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            onClick={onClose}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-brand-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100',
              )
            }
          >
            <Icon className="h-4 w-4" />
            {item.label}
          </NavLink>
        );
      });

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={onClose} />
      )}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 w-64 transform border-r border-gray-200 bg-white transition-transform lg:static lg:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        <div className="flex h-16 items-center justify-between border-b border-gray-200 px-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-md bg-brand-600 text-sm font-bold text-white">
              SC
            </div>
            <span className="font-semibold text-gray-900">Contábil</span>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 lg:hidden">
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex flex-col gap-1 p-4">
          {renderItems(NAV_ITEMS)}

          <div className="mt-4 border-t border-gray-200 pt-4">
            <p className="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-gray-500">
              Administração
            </p>
            {renderItems(ADMIN_ITEMS)}
          </div>
        </nav>
      </aside>
    </>
  );
}
