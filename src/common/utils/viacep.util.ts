export interface EnderecoViaCep {
  cep: string;
  logradouro: string;
  complemento: string;
  bairro: string;
  localidade: string;
  uf: string;
  ibge?: string;
  erro?: boolean;
}

export async function buscarCep(cep: string): Promise<EnderecoViaCep | null> {
  const limpo = cep.replace(/\D/g, '');
  if (limpo.length !== 8) return null;

  try {
    const res = await fetch(`https://viacep.com.br/ws/${limpo}/json/`);
    if (!res.ok) return null;
    const data = (await res.json()) as EnderecoViaCep;
    if (data.erro) return null;
    return data;
  } catch {
    return null;
  }
}
