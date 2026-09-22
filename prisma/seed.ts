import { PrismaClient, RegimeTributario, AnexoSimples } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const permissoes = [
    'empresa.criar', 'empresa.editar', 'empresa.excluir', 'empresa.ver',
    'lancamento.criar', 'lancamento.editar', 'lancamento.estornar', 'lancamento.ver',
    'documento.importar', 'documento.ver',
    'conciliacao.executar', 'conciliacao.ver',
    'apuracao.calcular', 'apuracao.ver',
    'relatorio.gerar', 'relatorio.ver',
    'usuario.gerenciar', 'auditoria.ver',
  ];

  for (const codigo of permissoes) {
    await prisma.permission.upsert({ where: { codigo }, update: {}, create: { codigo } });
  }

  const bancos = [
    { codigo: '001', nome: 'Banco do Brasil' },
    { codigo: '033', nome: 'Santander' },
    { codigo: '104', nome: 'Caixa Econômica Federal' },
    { codigo: '237', nome: 'Bradesco' },
    { codigo: '341', nome: 'Itaú Unibanco' },
    { codigo: '260', nome: 'Nu Pagamentos (Nubank)' },
    { codigo: '077', nome: 'Banco Inter' },
    { codigo: '336', nome: 'Banco C6' },
  ];

  for (const b of bancos) {
    await prisma.banco.upsert({ where: { codigo: b.codigo }, update: {}, create: b });
  }

  const faixasSimples = [
    { faixa: 1, inicial: 0, final: 180000, aliquota: 0.04, deduzir: 0 },
    { faixa: 2, inicial: 180000.01, final: 360000, aliquota: 0.073, deduzir: 5940 },
    { faixa: 3, inicial: 360000.01, final: 720000, aliquota: 0.095, deduzir: 13860 },
    { faixa: 4, inicial: 720000.01, final: 1800000, aliquota: 0.107, deduzir: 22500 },
    { faixa: 5, inicial: 1800000.01, final: 3600000, aliquota: 0.143, deduzir: 87300 },
    { faixa: 6, inicial: 3600000.01, final: 4800000, aliquota: 0.19, deduzir: 378000 },
  ];

  for (const f of faixasSimples) {
    await prisma.tabelaTributaria.create({
      data: {
        regime: RegimeTributario.SIMPLES,
        anexo: AnexoSimples.I,
        faixa: f.faixa,
        valorInicial: f.inicial,
        valorFinal: f.final,
        aliquota: f.aliquota,
        parcelaDeduzir: f.deduzir,
        vigenciaInicio: new Date('2026-01-01'),
      },
    });
  }

  console.log('✅ Seed concluído');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
