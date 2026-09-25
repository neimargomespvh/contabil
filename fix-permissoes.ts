import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const PERMISSOES = [
  'empresa.criar', 'empresa.editar', 'empresa.excluir', 'empresa.ver',
  'lancamento.criar', 'lancamento.editar', 'lancamento.estornar', 'lancamento.ver',
  'documento.importar', 'documento.ver', 'documento.excluir',
  'conciliacao.executar', 'conciliacao.ver',
  'apuracao.calcular', 'apuracao.ver',
  'relatorio.gerar', 'relatorio.ver',
  'usuario.gerenciar', 'auditoria.ver',
  'regra.criar', 'regra.editar', 'regra.excluir', 'regra.ver',
  'socio.criar', 'socio.editar', 'socio.excluir', 'socio.ver',
  'plano-contas.criar', 'plano-contas.editar', 'plano-contas.excluir', 'plano-contas.ver',
  'centro-custo.criar', 'centro-custo.editar', 'centro-custo.excluir', 'centro-custo.ver',
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

  console.log('🔧 Associando permissões a todos os roles admin...');

  const rolesAdmin = await prisma.role.findMany({ where: { nome: 'admin' } });
  const todas = await prisma.permission.findMany({
    where: { codigo: { in: PERMISSOES } },
  });

  for (const role of rolesAdmin) {
    await prisma.rolePermission.createMany({
      data: todas.map((p) => ({ roleId: role.id, permissionId: p.id })),
      skipDuplicates: true,
    });
    console.log(`  ✅ Role ${role.id} (tenant ${role.tenantId})`);
  }

  console.log('✅ Pronto!');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
