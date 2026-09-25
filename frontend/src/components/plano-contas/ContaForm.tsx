import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import type { ContaArvore } from '@/types';
import type { CreateContaPayload } from '@/services/plano-contas.service';

const schema = z.object({
  codigo: z.string().min(1, 'Obrigatório').max(30),
  nome: z.string().min(2, 'Mínimo 2 caracteres').max(200),
  natureza: z.enum(['ATIVO', 'PASSIVO', 'PATRIMONIO_LIQUIDO', 'RECEITA', 'DESPESA', 'CUSTO']),
  tipo: z.enum(['SINTETICA', 'ANALITICA']),
  aceitaLancamento: z.boolean(),
  dreLinha: z.string().max(50).optional().or(z.literal('')),
});

type FormData = z.infer<typeof schema>;

interface Props {
  conta?: ContaArvore | null;
  contaPai?: ContaArvore | null;
  onSubmit: (payload: CreateContaPayload) => void;
  onCancel: () => void;
  loading?: boolean;
}

export function ContaForm({ conta, contaPai, onSubmit, onCancel, loading }: Props) {
  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: conta
      ? {
          codigo: conta.codigo,
          nome: conta.nome,
          natureza: conta.natureza,
          tipo: conta.tipo,
          aceitaLancamento: conta.aceitaLancamento,
          dreLinha: conta.dreLinha ?? '',
        }
      : {
          codigo: contaPai ? `${contaPai.codigo}.` : '',
          nome: '',
          natureza: contaPai?.natureza ?? 'ATIVO',
          tipo: 'ANALITICA',
          aceitaLancamento: true,
          dreLinha: '',
        },
  });

  const tipo = watch('tipo');

  useEffect(() => {
    if (tipo === 'SINTETICA') {
      setValue('aceitaLancamento', false);
    }
  }, [tipo, setValue]);

    const submit = (data: FormData) => {
    const payload: CreateContaPayload = {
      codigo: data.codigo,
      nome: data.nome,
      natureza: data.natureza,
      tipo: data.tipo,
      contaPaiId: conta?.contaPaiId ?? contaPai?.id ?? null,
      dreLinha: data.dreLinha || null,
    };
    onSubmit(payload);
  };

  return (
    <form onSubmit={handleSubmit(submit)} className="space-y-4">
      {contaPai && (
        <div className="rounded-md bg-blue-50 px-3 py-2 text-xs text-blue-700">
          Subconta de <strong>{contaPai.codigo} — {contaPai.nome}</strong>
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div>
          <Label htmlFor="codigo">Código *</Label>
          <Input
            id="codigo"
            {...register('codigo')}
            placeholder="1.1.1.01"
            error={errors.codigo?.message}
          />
        </div>

        <div>
          <Label htmlFor="natureza">Natureza *</Label>
          <select id="natureza" {...register('natureza')} className="input-base">
            <option value="ATIVO">Ativo</option>
            <option value="PASSIVO">Passivo</option>
            <option value="PATRIMONIO_LIQUIDO">Patrimônio Líquido</option>
            <option value="RECEITA">Receita</option>
            <option value="DESPESA">Despesa</option>
            <option value="CUSTO">Custo</option>
          </select>
        </div>
      </div>

      <div>
        <Label htmlFor="nome">Nome *</Label>
        <Input
          id="nome"
          {...register('nome')}
          placeholder="Caixa"
          error={errors.nome?.message}
        />
      </div>

      <div>
        <Label htmlFor="tipo">Tipo *</Label>
        <select id="tipo" {...register('tipo')} className="input-base">
          <option value="SINTETICA">Sintética (agrupadora)</option>
          <option value="ANALITICA">Analítica (aceita lançamento)</option>
        </select>
      </div>

      {tipo === 'ANALITICA' && (
        <div className="flex items-center gap-2">
          <input
            id="aceitaLancamento"
            type="checkbox"
            {...register('aceitaLancamento')}
            className="h-4 w-4"
          />
          <Label htmlFor="aceitaLancamento">Aceita lançamento</Label>
        </div>
      )}

      <div>
        <Label htmlFor="dreLinha">Linha da DRE</Label>
        <select id="dreLinha" {...register('dreLinha')} className="input-base">
          <option value="">— Nenhuma —</option>
          <option value="RECEITA_BRUTA">Receita Bruta</option>
          <option value="CMV">CMV</option>
          <option value="DESPESAS_OPERACIONAIS">Despesas Operacionais</option>
          <option value="DESPESAS_ADMINISTRATIVAS">Despesas Administrativas</option>
          <option value="DESPESAS_COMERCIAIS">Despesas Comerciais</option>
          <option value="DESPESAS_FINANCEIRAS">Despesas Financeiras</option>
        </select>
      </div>

      <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          Cancelar
        </Button>
        <Button type="submit" loading={loading}>
          {conta ? 'Salvar alterações' : 'Criar conta'}
        </Button>
      </div>
    </form>
  );
}
