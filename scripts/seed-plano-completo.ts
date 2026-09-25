import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface C {
  codigo: string;
  nome: string;
  natureza: any;
  pai?: string;
  aceita?: boolean;
  dre?: string;
}

const CONTAS: C[] = [
  { codigo: '1.1', nome: 'ATIVO CIRCULANTE', natureza: 'ATIVO', pai: '1' },
  { codigo: '1.1.1', nome: 'DISPONIBILIDADES', natureza: 'ATIVO', pai: '1.1' },
  { codigo: '1.1.1.01', nome: 'Caixa', natureza: 'ATIVO', pai: '1.1.1', aceita: true },
  { codigo: '1.1.1.02', nome: 'Banco Conta Movimento', natureza: 'ATIVO', pai: '1.1.1', aceita: true },
  { codigo: '1.1.2', nome: 'CLIENTES', natureza: 'ATIVO', pai: '1.1' },
  { codigo: '1.1.2.01', nome: 'Clientes a Receber', natureza: 'ATIVO', pai: '1.1.2', aceita: true },
  { codigo: '1.1.3', nome: 'ESTOQUES', natureza: 'ATIVO', pai: '1.1' },
  { codigo: '1.1.3.01', nome: 'Mercadorias para Revenda', natureza: 'ATIVO', pai: '1.1.3', aceita: true },
  { codigo: '1.2', nome: 'ATIVO NAO CIRCULANTE', natureza: 'ATIVO', pai: '1' },
  { codigo: '1.2.1', nome: 'IMOBILIZADO', natureza: 'ATIVO', pai: '1.2' },
  { codigo: '1.2.1.01', nome: 'Moveis e Utensilios', natureza: 'ATIVO', pai: '1.2.1', aceita: true },
  { codigo: '2.1', nome: 'PASSIVO CIRCULANTE', natureza: 'PASSIVO', pai: '2' },
  { codigo: '2.1.1', nome: 'FORNECEDORES', natureza: 'PASSIVO', pai: '2.1' },
  { codigo: '2.1.1.01', nome: 'Fornecedores a Pagar', natureza: 'PASSIVO', pai: '2.1.1', aceita: true },
  { codigo: '2.1.2', nome: 'OBRIGACOES TRIBUTARIAS', natureza: 'PASSIVO', pai: '2.1' },
  { codigo: '2.1.2.01', nome: 'ICMS a Recolher', natureza: 'PASSIVO', pai: '2.1.2', aceita: true },
  { codigo: '2.1.2.02', nome: 'PIS a Recolher', natureza: 'PASSIVO', pai: '2.1.2', aceita: true },
  { codigo: '2.1.2.03', nome: 'COFINS a Recolher', natureza: 'PASSIVO', pai: '2.1.2', aceita: true },
  { codigo: '2.1.3', nome: 'OBRIGACOES TRABALHISTAS', natureza: 'PASSIVO', pai: '2.1' },
  { codigo: '2.1.3.01', nome: 'Salarios a Pagar', natureza: 'PASSIVO', pai: '2.1.3', aceita: true },
  { codigo: '2.1.3.02', nome: 'FGTS a Recolher', natureza: 'PASSIVO', pai: '2.1.3', aceita: true },
  { codigo: '2.1.3.03', nome: 'INSS a Recolher', natureza: 'PASSIVO', pai: '2.1.3', aceita: true },
  { codigo: '2.3', nome: 'PATRIMONIO LIQUIDO', natureza: 'PATRIMONIO_LIQUIDO', pai: '2' },
  { codigo: '2.3.1', nome: 'CAPITAL SOCIAL', natureza: 'PATRIMONIO_LIQUIDO', pai: '2.3' },
  { codigo: '2.3.1.01', nome: 'Capital Social Integralizado', natureza: 'PATRIMONIO_LIQUIDO', pai: '2.3.1', aceita: true },
  { codigo: '2.3.2', nome: 'LUCROS E PREJUIZOS', natureza: 'PATRIMONIO_LIQUIDO', pai: '2.3' },
  { codigo: '2.3.2.01', nome: 'Lucros Acumulados', natureza: 'PATRIMONIO_LIQUIDO', pai: '2.3.2', aceita: true },
  { codigo: '2.3.2.02', nome: 'Prejuizos Acumulados', natureza: 'PATRIMONIO_LIQUIDO', pai: '2.3.2', aceita: true },
  { codigo: '3.1', nome: 'RECEITA BRUTA', natureza: 'RECEITA', pai: '3', dre: 'RECEITA_BRUTA' },
  { codigo: '3.1.1', nome: 'RECEITAS DE VENDAS', natureza: 'RECEITA', pai: '3.1', dre: 'RECEITA_BRUTA' },
  { codigo: '3.1.1.01', nome: 'Receita de Vendas de Mercadorias', natureza: 'RECEITA', pai: '3.1.1', aceita: true, dre: 'RECEITA_BRUTA' },
  { codigo: '3.1.1.02', nome: 'Receita de Servicos', natureza: 'RECEITA', pai: '3.1.1', aceita: true, dre: 'RECEITA_BRUTA' },
  { codigo: '4.1', nome: 'CUSTO DAS VENDAS', natureza: 'CUSTO', pai: '4', dre: 'CMV' },
  { codigo: '4.1.1', nome: 'CMV - CUSTO DAS MERCADORIAS VENDIDAS', natureza: 'CUSTO', pai: '4.1', dre: 'CMV' },
  { codigo: '4.1.1.01', nome: 'Custo das Mercadorias Vendidas', natureza: 'CUSTO', pai: '4.1.1', aceita: true, dre: 'CMV' },
  { codigo: '5.1', nome: 'DESPESAS OPERACIONAIS', natureza: 'DESPESA', pai: '5', dre: 'DESPESAS_OPERACIONAIS' },
  { codigo: '5.1.1', nome: 'DESPESAS ADMINISTRATIVAS', natureza: 'DESPESA', pai: '5.1', dre: 'DESPESAS_ADMINISTRATIVAS' },
  { codigo: '5.1.1.01', nome: 'Salarios', natureza: 'DESPESA', pai: '5.1.1', aceita: true, dre: 'DESPESAS_ADMINISTRATIVAS' },
  { codigo: '5.1.1.02', nome: 'Aluguel', natureza: 'DESPESA', pai: '5.1.1', aceita: true, dre: 'DESPESAS_ADMINISTRATIVAS' },
  { codigo: '5.1.1.03', nome: 'Energia Eletrica', natureza: 'DESPESA', pai: '5.1.1', aceita: true, dre: 'DESPESAS_ADMINISTRATIVAS' },
  { codigo: '5.1.1.04', nome: 'Telefone e Internet', natureza: 'DESPESA', pai: '5.1.1', aceita: true, dre: 'DESPESAS_ADMINISTRATIVAS' },
  { codigo: '5.1.1.05', nome: 'Material de Escritorio', natureza: 'DESPESA', pai: '5.1.1', aceita: true, dre: 'DESPESAS_ADMINISTRATIVAS' },
  { codigo: '5.1.2', nome: 'DESPESAS COM VENDAS', natureza: 'DESPESA', pai: '5.1', dre: 'DESPESAS_COMERCIAIS' },
  { codigo: '5.1.2.01', nome: 'Comissoes sobre Vendas', natureza: 'DESPESA', pai: '5.1.2', aceita: true, dre: 'DESPESAS_COMERCIAIS' },
  { codigo: '5.2', nome: 'DESPESAS FINANCEIRAS', natureza: 'DESPESA', pai: '5', dre: 'DESPESAS_FINANCEIRAS' },
  { codigo: '5.2.1.01', nome: 'Juros Passivos', natureza: 'DESPESA', pai: '5.2', aceita: true, dre: 'DESPESAS_FINANCEIRAS' },
  { codigo: '5.2.1.02', nome: 'Tarifas Bancarias', natureza: 'DESPESA', pai: '5.2', aceita: true, dre: 'DESPESAS_FINANCEIRAS' },
];

async function main() {
  const planoId = process.argv[2];
  if (!planoId) { console.error('Uso: npx tsx scripts/seed-plano-completo.ts <PLANO_ID>'); process.exit(1); }

  const plano = await prisma.planoContas.findUnique({ where: { id: planoId } });
  if (!plano) { console.error('Plano nao encontrado:', planoId); process.exit(1); }

  console.log('Plano:', plano.nome);
  console.log('Tenant:', plano.tenantId);
  console.log('');

  const mapa = new Map<string, string>();
  const existentes = await prisma.conta.findMany({
    where: { planoContasId: planoId },
    select: { id: true, codigo: true },
  });
  for (const c of existentes) mapa.set(c.codigo, c.id);

  let criadas = 0, puladas = 0;

  for (const conta of CONTAS) {
    if (mapa.has(conta.codigo)) { puladas++; continue; }

    const paiId = conta.pai ? mapa.get(conta.pai) ?? null : null;
    const c = await prisma.conta.create({
      data: {
        tenantId: plano.tenantId,
        planoContasId: planoId,
        contaPaiId: paiId,
        codigo: conta.codigo,
        nome: conta.nome,
        natureza: conta.natureza,
        tipo: conta.aceita ? 'ANALITICA' : 'SINTETICA',
        grau: conta.codigo.split('.').length,
        aceitaLancamento: conta.aceita ?? false,
        dreLinha: conta.dre ?? null,
        status: 'ATIVO',
      },
    });
    mapa.set(conta.codigo, c.id);
    criadas++;
    console.log('  +', conta.codigo, '-', conta.nome);
  }

  console.log('');
  console.log(`OK: ${criadas} criadas, ${puladas} ja existiam`);
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
