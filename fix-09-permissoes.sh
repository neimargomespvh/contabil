#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

# ============================================================
# 1. SINCRONIZAR PERMISSÕES NO BANCO
# ============================================================
echo "🔧 Sincronizando permissões..."

docker exec -i contabil-postgres psql -U postgres -d contabil <<'SQL'
-- Inserir todas as permissões que o sistema usa (idempotente)
INSERT INTO permissions (id, codigo, descricao) VALUES
  (gen_random_uuid(), 'empresa.criar', 'Criar empresas'),
  (gen_random_uuid(), 'empresa.editar', 'Editar empresas'),
  (gen_random_uuid(), 'empresa.excluir', 'Excluir empresas'),
  (gen_random_uuid(), 'empresa.ver', 'Visualizar empresas'),
  (gen_random_uuid(), 'socio.criar', 'Criar sócios'),
  (gen_random_uuid(), 'socio.editar', 'Editar sócios'),
  (gen_random_uuid(), 'socio.excluir', 'Excluir sócios'),
  (gen_random_uuid(), 'socio.ver', 'Visualizar sócios'),
  (gen_random_uuid(), 'plano.criar', 'Criar planos de contas'),
  (gen_random_uuid(), 'plano.editar', 'Editar planos de contas'),
  (gen_random_uuid(), 'plano.ver', 'Visualizar planos de contas'),
  (gen_random_uuid(), 'lancamento.criar', 'Criar lançamentos'),
  (gen_random_uuid(), 'lancamento.editar', 'Editar lançamentos'),
  (gen_random_uuid(), 'lancamento.estornar', 'Estornar lançamentos'),
  (gen_random_uuid(), 'lancamento.ver', 'Visualizar lançamentos'),
  (gen_random_uuid(), 'documento.importar', 'Importar documentos fiscais'),
  (gen_random_uuid(), 'documento.excluir', 'Excluir documentos fiscais'),
  (gen_random_uuid(), 'documento.ver', 'Visualizar documentos fiscais'),
  (gen_random_uuid(), 'conciliacao.executar', 'Executar conciliação bancária'),
  (gen_random_uuid(), 'conciliacao.ver', 'Visualizar conciliação'),
  (gen_random_uuid(), 'apuracao.calcular', 'Calcular apurações tributárias'),
  (gen_random_uuid(), 'apuracao.ver', 'Visualizar apurações'),
  (gen_random_uuid(), 'relatorio.gerar', 'Gerar relatórios'),
  (gen_random_uuid(), 'relatorio.ver', 'Visualizar relatórios'),
  (gen_random_uuid(), 'usuario.gerenciar', 'Gerenciar usuários'),
  (gen_random_uuid(), 'usuario.ver', 'Visualizar usuários'),
  (gen_random_uuid(), 'role.gerenciar', 'Gerenciar perfis e permissões'),
  (gen_random_uuid(), 'role.ver', 'Visualizar perfis'),
  (gen_random_uuid(), 'auditoria.ver', 'Visualizar auditoria')
ON CONFLICT (codigo) DO UPDATE
  SET descricao = EXCLUDED.descricao;

-- Mostrar total
SELECT COUNT(*) AS total_permissoes FROM permissions;
SQL

echo ""

# ============================================================
# 2. CONCEDER TODAS AS PERMISSÕES AO ROLE "admin" DE CADA TENANT
# ============================================================
echo "🔧 Concedendo todas as permissões ao role admin..."

docker exec -i contabil-postgres psql -U postgres -d contabil <<'SQL'
-- Inserir role_permissions para todos os roles "admin" que não as têm
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.nome = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Mostrar quantas permissões o admin tem agora
SELECT
  r.nome AS role,
  t.nome AS tenant,
  COUNT(rp.permission_id) AS total_permissoes
FROM roles r
JOIN tenants t ON t.id = r.tenant_id
LEFT JOIN role_permissions rp ON rp.role_id = r.id
WHERE r.nome = 'admin'
GROUP BY r.id, r.nome, t.nome;
SQL

echo ""
echo "✅ Permissões sincronizadas!"