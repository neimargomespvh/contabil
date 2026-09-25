import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const PERMISSOES = [
  // Empresas
  'empresa.criar', 'empresa.editar', 'empresa.excluir', 'empresa.ver',
  // Lançamentos
  'lancamento.criar', 'lancamento.editar', 'lancamento.estornar', 'lancamento.ver',
  // Documentos fiscais
  'documento.importar', 'documento.ver', 'documento.excluir',
  // Conciliação
  'conciliacao.executar', 'conciliacao.ver',
  // Apuração
  'apuracao.calcular', 'apuracao.ver',
  // Relatórios
  'relatorio.gerar', 'relatorio.ver',
  // Usuários e auditoria
  'usuario.gerenciar', 'auditoria.ver',
  // Regras de contabilização
  'regra.criar', 'regra.editar', 'regra.excluir', 'regra.ver',
  // Sócios
  'socio.criar', 'socio.editar', 'socio.excluir', 'socio.ver',
  // Plano de contas (AMBAS variantes)
  'plano.criar', 'plano.editar', 'plano.excluir', 'plano.ver',
  'plano-contas.criar', 'plano-contas.editar', 'plano-contas.excluir', 'plano-contas.ver',
  // Contas (variantes)
  'conta.criar', 'conta.editar', 'conta.excluir', 'conta.ver',
  // Centros de custo
  'centro-custo.criar', 'centro-custo.editar', 'centro-custo.excluir', 'centro-custo.ver',
  // Contas bancárias
  'conta-bancaria.criar', 'conta-bancaria.editar', 'conta-bancaria.excluir', 'conta-bancaria.ver',
];

async function main() {
  console.log('🔧 Populando permissões globais...');

  for (const codigo of PERMISSOES) {
    await prisma.permission.upsert({
      where: { codigo },
      update: {},
      create: { codigo },
    });
  }

  console.log(`✅ ${PERMISSOES.length} permissões garantidas`);

  console.log('🔧 Associando a todos os roles admin...');

  const rolesAdmin = await prisma.role.findMany({ where: { nome: 'admin' } });
  const todas = await prisma.permission.findMany({
    where: { codigo: { in: PERMISSOES } },
  });

  for (const role of rolesAdmin) {
    await prisma.rolePermission.createMany({
      data: todas.map((p) => ({ roleId: role.id, permissionId: p.id })),
      skipDuplicates: true,
    });
    console.log(`  ✅ Role ${role.id}`);
  }

  console.log('');
  console.log('✅ Pronto! Faça logout e login novamente para o token pegar as permissões novas.');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
