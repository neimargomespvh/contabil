import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { useCriarSocio, useAtualizarSocio } from '@/hooks/useSocios';
import { validarCpf, mascararCpf } from '@/lib/validacoes';
import type { Socio, CreateSocioPayload } from '@/types';

const schema = z.object({
  nome: z.string().min(3, 'Mínimo 3 caracteres').max(200),
  cpf: z.string().refine(validarCpf, 'CPF inválido'),
  participacao: z
    .number({ invalid_type_error: 'Informe um número' })
    .min(0.000001, 'Deve ser maior que zero')
    .max(100, 'Máximo 100%'),
  proLabore: z.number().min(0).optional(),
  dataEntrada: z.string().optional().or(z.literal('')),
});

type FormData = z.infer<typeof schema>;

interface SocioModalProps {
  isOpen: boolean;
  onClose: () => void;
  empresaId: string;
  socio?: Socio | null;
  participacaoDisponivel: number;
}

export function SocioModal({
  isOpen,
  onClose,
  empresaId,
  socio,
  participacaoDisponivel,
}: SocioModalProps) {
  const criar = useCriarSocio();
  const atualizar = useAtualizarSocio(empresaId);

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
    reset,
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      nome: '',
      cpf: '',
      participacao: 0,
      proLabore: undefined,
      dataEntrada: '',
    },
  });

  useEffect(() => {
    if (isOpen) {
      reset(
        socio
          ? {
              nome: socio.nome,
              cpf: mascararCpf(socio.cpf),
              participacao: Number(socio.participacao),
              proLabore: socio.proLabore ? Number(socio.proLabore) : undefined,
              dataEntrada: socio.dataEntrada?.slice(0, 10) ?? '',
            }
          : {
              nome: '',
              cpf: '',
              participacao: 0,
              proLabore: undefined,
              dataEntrada: '',
            },
      );
    }
  }, [isOpen, socio, reset]);

  const handleCpfChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setValue('cpf', mascararCpf(e.target.value));
  };

  const submit = (data: FormData) => {
    const payload: CreateSocioPayload = {
      empresaId,
      nome: data.nome,
      cpf: data.cpf.replace(/\D/g, ''),
      participacao: Number(data.participacao),
      proLabore: data.proLabore ? Number(data.proLabore) : undefined,
      dataEntrada: data.dataEntrada || undefined,
    };

    if (socio) {
      atualizar.mutate(
        {
          id: socio.id,
          payload: {
            nome: payload.nome,
            cpf: payload.cpf,
            participacao: payload.participacao,
            proLabore: payload.proLabore,
            dataEntrada: payload.dataEntrada,
          },
        },
        { onSuccess: onClose },
      );
    } else {
      criar.mutate(payload, { onSuccess: onClose });
    }
  };

  const loading = criar.isPending || atualizar.isPending;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={socio ? `Editar sócio — ${socio.nome}` : 'Novo sócio'}
      size="md"
    >
      <form onSubmit={handleSubmit(submit)} className="space-y-4">
        <div>
          <Label htmlFor="nome">Nome completo *</Label>
          <Input id="nome" {...register('nome')} error={errors.nome?.message} />
        </div>

        <div>
          <Label htmlFor="cpf">CPF *</Label>
          <Input
            id="cpf"
            {...register('cpf')}
            onChange={handleCpfChange}
            placeholder="000.000.000-00"
            error={errors.cpf?.message}
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <Label htmlFor="participacao">
              Participação (%) *
              {!socio && (
                <span className="ml-1 text-xs font-normal text-gray-400">
                  (até {participacaoDisponivel.toFixed(2)}%)
                </span>
              )}
            </Label>
            <Input
              id="participacao"
              type="number"
              step="0.000001"
              {...register('participacao', { valueAsNumber: true })}
              error={errors.participacao?.message}
            />
          </div>

          <div>
            <Label htmlFor="proLabore">Pró-labore (R$)</Label>
            <Input
              id="proLabore"
              type="number"
              step="0.01"
              {...register('proLabore', { valueAsNumber: true })}
            />
          </div>
        </div>

        <div>
          <Label htmlFor="dataEntrada">Data de entrada</Label>
          <Input id="dataEntrada" type="date" {...register('dataEntrada')} />
        </div>

        <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
          <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
            Cancelar
          </Button>
          <Button type="submit" loading={loading}>
            {socio ? 'Salvar alterações' : 'Adicionar sócio'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
