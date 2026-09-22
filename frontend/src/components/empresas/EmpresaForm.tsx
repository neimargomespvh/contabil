import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { toast } from '@/components/ui/Toast';
import { viacepService } from '@/services/viacep.service';
import {
  validarCnpj,
  validarCpf,
  mascararCnpj,
  mascararCpf,
  mascararCep,
} from '@/lib/validacoes';
import type { Empresa, CreateEmpresaPayload } from '@/types';

const schema = z.object({
  razaoSocial: z.string().min(3, 'Mínimo 3 caracteres').max(200),
  nomeFantasia: z.string().max(200).optional().or(z.literal('')),
  cnpj: z
    .string()
    .length(18, 'CNPJ incompleto')
    .refine(validarCnpj, 'CNPJ inválido'),
  inscricaoEstadual: z.string().max(20).optional().or(z.literal('')),
  inscricaoMunicipal: z.string().max(20).optional().or(z.literal('')),
  regimeTributario: z.enum(['SIMPLES', 'PRESUMIDO', 'REAL', 'MEI']),
  anexoSimples: z.enum(['', 'I', 'II', 'III', 'IV', 'V']).optional(),
  cnaePrincipal: z.string().max(10).optional().or(z.literal('')),
  dataAbertura: z.string().optional().or(z.literal('')),
  email: z.string().email('Email inválido').optional().or(z.literal('')),
  telefone: z.string().max(20).optional().or(z.literal('')),
  responsavelNome: z.string().max(200).optional().or(z.literal('')),
  responsavelCpf: z
    .string()
    .optional()
    .or(z.literal(''))
    .refine((v) => !v || validarCpf(v), 'CPF inválido'),
  observacoes: z.string().optional().or(z.literal('')),
  cep: z.string().optional().or(z.literal('')),
  logradouro: z.string().optional().or(z.literal('')),
  numero: z.string().optional().or(z.literal('')),
  complemento: z.string().optional().or(z.literal('')),
  bairro: z.string().optional().or(z.literal('')),
  cidade: z.string().optional().or(z.literal('')),
  uf: z.string().max(2).optional().or(z.literal('')),
});

type FormData = z.infer<typeof schema>;

interface EmpresaFormProps {
  empresa?: Empresa;
  onSubmit: (payload: CreateEmpresaPayload) => void;
  onCancel: () => void;
  loading?: boolean;
}

export function EmpresaForm({ empresa, onSubmit, onCancel, loading }: EmpresaFormProps) {
  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: empresa
      ? {
          razaoSocial: empresa.razaoSocial,
          nomeFantasia: empresa.nomeFantasia ?? '',
          cnpj: mascararCnpj(empresa.cnpj),
          inscricaoEstadual: empresa.inscricaoEstadual ?? '',
          inscricaoMunicipal: empresa.inscricaoMunicipal ?? '',
          regimeTributario: empresa.regimeTributario,
          anexoSimples: empresa.anexoSimples ?? '',
          cnaePrincipal: empresa.cnaePrincipal ?? '',
          dataAbertura: empresa.dataAbertura?.slice(0, 10) ?? '',
          email: empresa.email ?? '',
          telefone: empresa.telefone ?? '',
          responsavelNome: empresa.responsavelNome ?? '',
          responsavelCpf: empresa.responsavelCpf ? mascararCpf(empresa.responsavelCpf) : '',
          observacoes: empresa.observacoes ?? '',
          cep: empresa.endereco?.cep ? mascararCep(empresa.endereco.cep) : '',
          logradouro: empresa.endereco?.logradouro ?? '',
          numero: empresa.endereco?.numero ?? '',
          complemento: empresa.endereco?.complemento ?? '',
          bairro: empresa.endereco?.bairro ?? '',
          cidade: empresa.endereco?.cidade ?? '',
          uf: empresa.endereco?.uf ?? '',
        }
      : {
          regimeTributario: 'SIMPLES',
          anexoSimples: 'I',
        },
  });

  const regime = watch('regimeTributario');

  const handleCepChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const valor = mascararCep(e.target.value);
    setValue('cep', valor);

    if (valor.length === 9) {
      const dados = await viacepService.buscar(valor);
      if (dados) {
        setValue('logradouro', dados.logradouro);
        setValue('bairro', dados.bairro);
        setValue('cidade', dados.localidade);
        setValue('uf', dados.uf);
        toast.success('Endereço preenchido pelo ViaCEP');
      }
    }
  };

  const handleCnpjChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setValue('cnpj', mascararCnpj(e.target.value));
  };

  const handleCpfChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setValue('responsavelCpf', mascararCpf(e.target.value));
  };

  const submit = (data: FormData) => {
    const payload: CreateEmpresaPayload = {
      razaoSocial: data.razaoSocial,
      nomeFantasia: data.nomeFantasia || undefined,
      cnpj: data.cnpj.replace(/\D/g, ''),
      inscricaoEstadual: data.inscricaoEstadual || undefined,
      inscricaoMunicipal: data.inscricaoMunicipal || undefined,
      regimeTributario: data.regimeTributario,
      anexoSimples:
        data.regimeTributario === 'SIMPLES' && data.anexoSimples
          ? (data.anexoSimples as any)
          : undefined,
      cnaePrincipal: data.cnaePrincipal || undefined,
      dataAbertura: data.dataAbertura || undefined,
      email: data.email || undefined,
      telefone: data.telefone || undefined,
      responsavelNome: data.responsavelNome || undefined,
      responsavelCpf: data.responsavelCpf ? data.responsavelCpf.replace(/\D/g, '') : undefined,
      observacoes: data.observacoes || undefined,
      endereco:
        data.cep || data.logradouro || data.cidade
          ? {
              cep: data.cep?.replace(/\D/g, ''),
              logradouro: data.logradouro,
              numero: data.numero,
              complemento: data.complemento,
              bairro: data.bairro,
              cidade: data.cidade,
              uf: data.uf,
            }
          : undefined,
    };

    onSubmit(payload);
  };

  return (
    <form onSubmit={handleSubmit(submit)} className="space-y-6">
      {/* Dados principais */}
      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Dados da Empresa
        </h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <Label htmlFor="razaoSocial">Razão Social *</Label>
            <Input
              id="razaoSocial"
              {...register('razaoSocial')}
              error={errors.razaoSocial?.message}
            />
          </div>

          <div>
            <Label htmlFor="nomeFantasia">Nome Fantasia</Label>
            <Input id="nomeFantasia" {...register('nomeFantasia')} />
          </div>

          <div>
            <Label htmlFor="cnpj">CNPJ *</Label>
            <Input
              id="cnpj"
              {...register('cnpj')}
              onChange={handleCnpjChange}
              placeholder="00.000.000/0000-00"
              error={errors.cnpj?.message}
            />
          </div>

          <div>
            <Label htmlFor="inscricaoEstadual">Inscrição Estadual</Label>
            <Input id="inscricaoEstadual" {...register('inscricaoEstadual')} />
          </div>

          <div>
            <Label htmlFor="inscricaoMunicipal">Inscrição Municipal</Label>
            <Input id="inscricaoMunicipal" {...register('inscricaoMunicipal')} />
          </div>

          <div>
            <Label htmlFor="regimeTributario">Regime Tributário *</Label>
            <select
              id="regimeTributario"
              {...register('regimeTributario')}
              className="input-base"
            >
              <option value="SIMPLES">Simples Nacional</option>
              <option value="PRESUMIDO">Lucro Presumido</option>
              <option value="REAL">Lucro Real</option>
              <option value="MEI">MEI</option>
            </select>
          </div>

          {regime === 'SIMPLES' && (
            <div>
              <Label htmlFor="anexoSimples">Anexo do Simples</Label>
              <select id="anexoSimples" {...register('anexoSimples')} className="input-base">
                <option value="">— Selecione —</option>
                <option value="I">Anexo I — Comércio</option>
                <option value="II">Anexo II — Indústria</option>
                <option value="III">Anexo III — Serviços</option>
                <option value="IV">Anexo IV — Serviços (construção)</option>
                <option value="V">Anexo V — Serviços (tecnologia)</option>
              </select>
            </div>
          )}

          <div>
            <Label htmlFor="cnaePrincipal">CNAE Principal</Label>
            <Input id="cnaePrincipal" {...register('cnaePrincipal')} />
          </div>

          <div>
            <Label htmlFor="dataAbertura">Data de Abertura</Label>
            <Input id="dataAbertura" type="date" {...register('dataAbertura')} />
          </div>
        </div>
      </div>

      {/* Endereço */}
      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Endereço
        </h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-6">
          <div className="sm:col-span-2">
            <Label htmlFor="cep">CEP</Label>
            <Input
              id="cep"
              {...register('cep')}
              onChange={handleCepChange}
              placeholder="00000-000"
            />
          </div>

          <div className="sm:col-span-4">
            <Label htmlFor="logradouro">Logradouro</Label>
            <Input id="logradouro" {...register('logradouro')} />
          </div>

          <div className="sm:col-span-2">
            <Label htmlFor="numero">Número</Label>
            <Input id="numero" {...register('numero')} />
          </div>

          <div className="sm:col-span-4">
            <Label htmlFor="complemento">Complemento</Label>
            <Input id="complemento" {...register('complemento')} />
          </div>

          <div className="sm:col-span-3">
            <Label htmlFor="bairro">Bairro</Label>
            <Input id="bairro" {...register('bairro')} />
          </div>

          <div className="sm:col-span-2">
            <Label htmlFor="cidade">Cidade</Label>
            <Input id="cidade" {...register('cidade')} />
          </div>

          <div className="sm:col-span-1">
            <Label htmlFor="uf">UF</Label>
            <Input id="uf" {...register('uf')} maxLength={2} />
          </div>
        </div>
      </div>

      {/* Contato */}
      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Contato e Responsável
        </h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" {...register('email')} />
          </div>

          <div>
            <Label htmlFor="telefone">Telefone</Label>
            <Input id="telefone" {...register('telefone')} placeholder="(00) 00000-0000" />
          </div>

          <div>
            <Label htmlFor="responsavelNome">Nome do Responsável</Label>
            <Input id="responsavelNome" {...register('responsavelNome')} />
          </div>

          <div>
            <Label htmlFor="responsavelCpf">CPF do Responsável</Label>
            <Input
              id="responsavelCpf"
              {...register('responsavelCpf')}
              onChange={handleCpfChange}
              placeholder="000.000.000-00"
              error={errors.responsavelCpf?.message}
            />
          </div>
        </div>
      </div>

      {/* Observações */}
      <div>
        <Label htmlFor="observacoes">Observações</Label>
        <textarea
          id="observacoes"
          {...register('observacoes')}
          rows={3}
          className="input-base h-auto py-2"
          placeholder="Anotações internas sobre a empresa..."
        />
      </div>

      <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          Cancelar
        </Button>
        <Button type="submit" loading={loading}>
          {empresa ? 'Salvar alterações' : 'Cadastrar empresa'}
        </Button>
      </div>
    </form>
  );
}
