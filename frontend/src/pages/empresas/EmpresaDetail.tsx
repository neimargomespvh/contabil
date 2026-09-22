import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, Pencil, Building2, Users, FileText } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Spinner } from '@/components/ui/Spinner';
import { EmpresaModal } from '@/components/empresas/EmpresaModal';
import { SociosTab } from '@/components/socios/SociosTab';
import { useEmpresa } from '@/hooks/useEmpresas';
import { formatCnpj, formatCpf } from '@/lib/format';
import { cn } from '@/lib/utils';

type Tab = 'dados' | 'socios' | 'lancamentos';

const REGIME_LABEL: Record<string, string> = {
  SIMPLES: 'Simples Nacional',
  PRESUMIDO: 'Lucro Presumido',
  REAL: 'Lucro Real',
  MEI: 'MEI',
};

export function EmpresaDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: empresa, isLoading } = useEmpresa(id ?? null);
  const [editOpen, setEditOpen] = useState(false);
  const [tab, setTab] = useState<Tab>('dados');

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size="lg" />
      </div>
    );
  }

  if (!empresa) {
    return (
      <div className="py-20 text-center">
        <p className="text-gray-500">Empresa não encontrada</p>
        <Link to="/empresas" className="mt-4 inline-block">
          <Button variant="outline">Voltar</Button>
        </Link>
      </div>
    );
  }

  const tabs = [
    { id: 'dados' as Tab, label: 'Dados', icon: Building2 },
    { id: 'socios' as Tab, label: 'Sócios', icon: Users },
    { id: 'lancamentos' as Tab, label: 'Lançamentos', icon: FileText },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <Link
          to="/empresas"
          className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
        >
          <ArrowLeft className="h-4 w-4" />
          Voltar para Empresas
        </Link>
      </div>

      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div className="flex items-start gap-4">
          <div className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-lg bg-brand-100 text-xl font-bold text-brand-700">
            {empresa.razaoSocial.charAt(0).toUpperCase()}
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{empresa.razaoSocial}</h1>
            <p className="text-sm text-gray-500">
              {empresa.nomeFantasia && `${empresa.nomeFantasia} · `}
              {formatCnpj(empresa.cnpj)}
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              <Badge variant={empresa.status === 'ATIVA' ? 'success' : 'default'}>
                {empresa.status}
              </Badge>
              <Badge variant="info">{REGIME_LABEL[empresa.regimeTributario]}</Badge>
              {empresa.anexoSimples && <Badge>Anexo {empresa.anexoSimples}</Badge>}
            </div>
          </div>
        </div>

        <Button onClick={() => setEditOpen(true)} variant="outline">
          <Pencil className="h-4 w-4" />
          Editar
        </Button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex gap-6">
          {tabs.map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.id}
                onClick={() => setTab(t.id)}
                className={cn(
                  'flex items-center gap-2 border-b-2 px-1 py-3 text-sm font-medium transition-colors',
                  tab === t.id
                    ? 'border-brand-600 text-brand-600'
                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                )}
              >
                <Icon className="h-4 w-4" />
                {t.label}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Conteúdo */}
      {tab === 'dados' && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Informações Gerais</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <Field label="CNPJ" value={formatCnpj(empresa.cnpj)} />
              <Field label="Razão Social" value={empresa.razaoSocial} />
              <Field label="Nome Fantasia" value={empresa.nomeFantasia || '—'} />
              <Field label="Inscrição Estadual" value={empresa.inscricaoEstadual || '—'} />
              <Field label="Inscrição Municipal" value={empresa.inscricaoMunicipal || '—'} />
              <Field label="CNAE Principal" value={empresa.cnaePrincipal || '—'} />
              <Field
                label="Data de Abertura"
                value={
                  empresa.dataAbertura
                    ? new Date(empresa.dataAbertura).toLocaleDateString('pt-BR')
                    : '—'
                }
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Endereço</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <Field label="CEP" value={empresa.endereco?.cep || '—'} />
              <Field label="Logradouro" value={empresa.endereco?.logradouro || '—'} />
              <Field label="Número" value={empresa.endereco?.numero || '—'} />
              <Field label="Complemento" value={empresa.endereco?.complemento || '—'} />
              <Field label="Bairro" value={empresa.endereco?.bairro || '—'} />
              <Field
                label="Cidade / UF"
                value={
                  empresa.endereco?.cidade
                    ? `${empresa.endereco.cidade} / ${empresa.endereco.uf}`
                    : '—'
                }
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Contato e Responsável</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <Field label="Email" value={empresa.email || '—'} />
              <Field label="Telefone" value={empresa.telefone || '—'} />
              <Field label="Responsável" value={empresa.responsavelNome || '—'} />
              <Field
                label="CPF Responsável"
                value={empresa.responsavelCpf ? formatCpf(empresa.responsavelCpf) : '—'}
              />
            </CardContent>
          </Card>

          {empresa.observacoes && (
            <Card>
              <CardHeader>
                <CardTitle>Observações</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="whitespace-pre-wrap text-sm text-gray-700">
                  {empresa.observacoes}
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {tab === 'socios' && <SociosTab empresaId={empresa.id} />}

      {tab === 'lancamentos' && (
        <div className="rounded-lg border-2 border-dashed border-gray-300 bg-white p-12 text-center">
          <FileText className="mx-auto h-10 w-10 text-gray-400" />
          <p className="mt-4 font-medium text-gray-900">Lançamentos contábeis</p>
          <p className="mt-1 text-sm text-gray-500">
            Será implementado no próximo pacote (A3)
          </p>
        </div>
      )}

      <EmpresaModal isOpen={editOpen} onClose={() => setEditOpen(false)} empresa={empresa} />
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4 border-b border-gray-100 pb-2 last:border-0">
      <span className="text-gray-500">{label}</span>
      <span className="text-right font-medium text-gray-900">{value}</span>
    </div>
  );
}
