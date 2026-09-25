import { useEffect } from 'react';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { ContaSelect } from '@/components/common/ContaSelect';
import { usePlanoAtivo } from '@/hooks/usePlanoContas';
import type {
  RegraContabilizacao,
  CreateRegraPayload,
  TipoDocumento,
} from '@/services/regras-contabilizacao.service';

const schema = z
  .object({
    nome: z.string().min(3, 'Mínimo 3 caracteres').max(200),
    prioridade: z.coerce.number().int().min(1, 'Mínimo 1'),
    tipoDoc: z.enum(['', 'NFE', 'NFCE', 'CTE', 'NFSE']).optional(),
    cfop: z
      .string()
      .optional()
      .or(z.literal(''))
      .refine((v) => !v || /^\d{4}$/.test(v), 'CFOP deve ter 4 dígitos'),
    cfopPrefix: z
      .string()
      .optional()
      .or(z.literal(''))
      .refine((v) => !v || /^\d{1,3}$/.test(v), 'Prefixo deve ter 1-3 dígitos'),
    ncm: z
      .string()
      .optional()
      .or(z.literal(''))
      .refine((v) => !v || /^\d{8}$/.test(v), 'NCM deve ter 8 dígitos'),
    ncmPrefix: z
      .string()
      .optional()
      .or(z.literal(''))
      .refine((v) => !v || /^\d{1,7}$/.test(v), 'Prefixo deve ter 1-7 dígitos'),
    emitenteCnpj: z
      .string()
      .optional()
      .or(z.literal(''))
      .refine((v) => !v || /^\d{14}$/.test(v), 'CNPJ deve ter 14 dígitos'),
    destinatarioCnpj: z
      .string()
      .optional()
      .or(z.literal(''))
      .refine((v) => !v || /^\d{14}$/.test(v), 'CNPJ deve ter 14 dígitos'),
    contaDebitoId: z.string().uuid('Selecione a conta de débito'),
    contaCreditoId: z.string().uuid('Selecione a conta de crédito'),
    historicoTemplate: z.string().max(500).optional().or(z.literal('')),
  })
  .refine(
    (d) =>
      d.cfop ||
      d.cfopPrefix ||
      d.ncm ||
      d.ncmPrefix ||
      d.emitenteCnpj ||
      d.destinatarioCnpj ||
      d.tipoDoc,
    { message: 'Informe ao menos um critério', path: ['cfop'] },
  );

type FormData = z.infer<typeof schema>;

interface Props {
  empresaId: string;
  regra?: RegraContabilizacao | null;
  onSubmit: (payload: CreateRegraPayload | any) => void;
  onCancel: () => void;
  loading?: boolean;
}

export function RegraForm({ empresaId, regra, onSubmit, onCancel, loading }: Props) {
  const { data: plano, isLoading: carregandoPlano } = usePlanoAtivo(empresaId);
  const planoId = plano?.id ?? null;
  const {
    register,
    handleSubmit,
    control,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema) as any,
    defaultValues: regra
      ? {
          nome: regra.nome,
          prioridade: regra.prioridade,
          tipoDoc: (regra.condicao?.tipo as any) ?? '',
          cfop: regra.condicao?.cfop ?? '',
          cfopPrefix: regra.condicao?.cfopPrefix ?? '',
          ncm: regra.condicao?.ncm ?? '',
          ncmPrefix: regra.condicao?.ncmPrefix ?? '',
          emitenteCnpj: regra.condicao?.emitenteCnpj ?? '',
          destinatarioCnpj: regra.condicao?.destinatarioCnpj ?? '',
          contaDebitoId: regra.contaDebitoId,
          contaCreditoId: regra.contaCreditoId,
          historicoTemplate: regra.historicoTemplate ?? '',
        }
      : {
          nome: '',
          prioridade: 1,
          tipoDoc: '',
          cfop: '',
          cfopPrefix: '',
          ncm: '',
          ncmPrefix: '',
          emitenteCnpj: '',
          destinatarioCnpj: '',
          contaDebitoId: '',
          contaCreditoId: '',
          historicoTemplate: 'NF {numero} - {emitente}',
        },
  });

  const submit = (data: FormData) => {
    const condicao: Record<string, any> = {};
    if (data.tipoDoc) condicao.tipo = data.tipoDoc;
    if (data.cfop) condicao.cfop = data.cfop;
    if (data.cfopPrefix) condicao.cfopPrefix = data.cfopPrefix;
    if (data.ncm) condicao.ncm = data.ncm;
    if (data.ncmPrefix) condicao.ncmPrefix = data.ncmPrefix;
    if (data.emitenteCnpj) condicao.emitenteCnpj = data.emitenteCnpj;
    if (data.destinatarioCnpj) condicao.destinatarioCnpj = data.destinatarioCnpj;

    const payload = {
      empresaId,
      nome: data.nome,
      prioridade: data.prioridade,
      condicao,
      contaDebitoId: data.contaDebitoId,
      contaCreditoId: data.contaCreditoId,
      historicoTemplate: data.historicoTemplate || undefined,
    };
    onSubmit(payload);
  };

  return (
    <form onSubmit={handleSubmit(submit)} className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="sm:col-span-2">
          <Label htmlFor="nome">Nome da regra *</Label>
          <Input
            id="nome"
            {...register('nome')}
            placeholder="Compra de mercadoria CFOP 5102"
            error={errors.nome?.message}
          />
        </div>
        <div>
          <Label htmlFor="prioridade">Prioridade *</Label>
          <Input
            id="prioridade"
            type="number"
            min={1}
            {...register('prioridade')}
            error={errors.prioridade?.message}
          />
          <p className="mt-1 text-[11px] text-gray-500">
            Menor = mais prioritária
          </p>
        </div>
      </div>

      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Condições (ao menos 1)
        </h3>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <div>
            <Label htmlFor="tipoDoc">Tipo</Label>
            <select id="tipoDoc" {...register('tipoDoc')} className="input-base">
              <option value="">Qualquer</option>
              <option value="NFE">NFe</option>
              <option value="NFCE">NFCe</option>
              <option value="CTE">CT-e</option>
              <option value="NFSE">NFS-e</option>
            </select>
          </div>
          <div>
            <Label htmlFor="cfop">CFOP exato</Label>
            <Input
              id="cfop"
              {...register('cfop')}
              placeholder="5102"
              maxLength={4}
              error={errors.cfop?.message}
            />
          </div>
          <div>
            <Label htmlFor="cfopPrefix">Prefixo CFOP</Label>
            <Input
              id="cfopPrefix"
              {...register('cfopPrefix')}
              placeholder="5"
              maxLength={3}
              error={errors.cfopPrefix?.message}
            />
          </div>
          <div>
            <Label htmlFor="ncm">NCM exato</Label>
            <Input
              id="ncm"
              {...register('ncm')}
              placeholder="12345678"
              maxLength={8}
              error={errors.ncm?.message}
            />
          </div>
          <div>
            <Label htmlFor="ncmPrefix">Prefixo NCM</Label>
            <Input
              id="ncmPrefix"
              {...register('ncmPrefix')}
              placeholder="1234"
              maxLength={7}
              error={errors.ncmPrefix?.message}
            />
          </div>
          <div className="sm:col-span-2">
            <Label htmlFor="emitenteCnpj">CNPJ Emitente</Label>
            <Input
              id="emitenteCnpj"
              {...register('emitenteCnpj')}
              placeholder="00000000000000"
              maxLength={14}
              error={errors.emitenteCnpj?.message}
            />
          </div>
          <div className="sm:col-span-2">
            <Label htmlFor="destinatarioCnpj">CNPJ Destinatário</Label>
            <Input
              id="destinatarioCnpj"
              {...register('destinatarioCnpj')}
              placeholder="00000000000000"
              maxLength={14}
              error={errors.destinatarioCnpj?.message}
            />
          </div>
        </div>
        {errors.cfop?.message && (
          <p className="mt-2 text-xs text-red-600">{errors.cfop.message}</p>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <Label htmlFor="contaDebitoId">Conta de débito *</Label>
          <Controller
            control={control}
            name="contaDebitoId"
            render={({ field }) => (
              <ContaSelect
                planoId={planoId}
                empresaId={empresaId}
                value={field.value}
                onChange={field.onChange}
                disabled={carregandoPlano}
              />
            )}
          />
          {errors.contaDebitoId && (
            <p className="mt-1 text-xs text-red-600">{errors.contaDebitoId.message}</p>
          )}
        </div>
        <div>
          <Label htmlFor="contaCreditoId">Conta de crédito *</Label>
          <Controller
            control={control}
            name="contaCreditoId"
            render={({ field }) => (
              <ContaSelect
                planoId={planoId}
                empresaId={empresaId}
                value={field.value}
                onChange={field.onChange}
                disabled={carregandoPlano}
              />
            )}
          />
          {errors.contaCreditoId && (
            <p className="mt-1 text-xs text-red-600">{errors.contaCreditoId.message}</p>
          )}
        </div>
      </div>

      <div>
        <Label htmlFor="historicoTemplate">Template do histórico</Label>
        <Input
          id="historicoTemplate"
          {...register('historicoTemplate')}
          placeholder="NF {numero} - {emitente}"
        />
        <p className="mt-1 text-[11px] text-gray-500">
          Variáveis: {'{numero}'}, {'{serie}'}, {'{emitente}'}, {'{chave}'}, {'{cfop}'}
        </p>
      </div>

      <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          Cancelar
        </Button>
        <Button type="submit" loading={loading}>
          {regra ? 'Salvar alterações' : 'Criar regra'}
        </Button>
      </div>
    </form>
  );
}
