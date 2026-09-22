#!/usr/bin/env bash
set -e

echo "============================================"
echo "🔍 DIAGNÓSTICO"
echo "============================================"

echo ""
echo "1️⃣  Total de permissões no banco:"
docker exec -i contabil-postgres psql -U postgres -d contabil -t -c \
  "SELECT COUNT(*) FROM permissions;"

echo ""
echo "2️⃣  Permissões do admin do seu tenant:"
docker exec -i contabil-postgres psql -U postgres -d contabil -c "
SELECT
  u.email,
  r.nome AS role,
  COUNT(rp.permission_id) AS total
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
LEFT JOIN roles r ON r.id = ur.role_id
LEFT JOIN role_permissions rp ON rp.role_id = r.id
WHERE u.email = 'neimargomes@gmail.com'
GROUP BY u.email, r.nome;
"

echo ""
echo "============================================"
echo "🔧 CORREÇÃO"
echo "============================================"

echo ""
echo "3️⃣  Inserindo permissões faltantes..."
docker exec -i contabil-postgres psql -U postgres -d contabil <<'SQL'
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
ON CONFLICT (codigo) DO NOTHING;
SQL

echo ""
echo "4️⃣  Concedendo TODAS as permissões ao role admin:"
docker exec -i contabil-postgres psql -U postgres -d contabil <<'SQL'
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.nome = 'admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;
SQL

echo ""
echo "5️⃣  Verificando resultado:"
docker exec -i contabil-postgres psql -U postgres -d contabil -c "
SELECT
  u.email,
  r.nome AS role,
  COUNT(rp.permission_id) AS total
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
LEFT JOIN roles r ON r.id = ur.role_id
LEFT JOIN role_permissions rp ON rp.role_id = r.id
WHERE u.email = 'neimargomes@gmail.com'
GROUP BY u.email, r.nome;
"

echo ""
echo "============================================"
echo "🔑 NOVO LOGIN"
echo "============================================"

export TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}' \
  | jq -r '.accessToken')

echo "Tamanho do token: ${#TOKEN}"

echo ""
echo "Permissões no token (contagem):"
echo "$TOKEN" | cut -d '.' -f 2 | base64 -d 2>/dev/null | jq '.permissions | length'

echo ""
echo "============================================"
echo "🧪 TESTE"
echo "============================================"

curl -s http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer $TOKEN" | jq

# Salvar para próximos comandos
cat > /tmp/contabil-env.sh <<EOF
export TOKEN="$TOKEN"
export CONTABIL_EMAIL="neimargomes@gmail.com"
export CONTABIL_SENHA="200644ng"
EOF

echo ""
echo "✅ Script concluído. Variáveis salvas em /tmp/contabil-env.sh"