# Terminal 1
npm run dev

# Terminal 2 — login
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimar@teste2.com","senha":"SenhaForte@123"}' \
  | jq -r '.accessToken')

# Pegar empresa existente
EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')
echo "Empresa: $EMPRESA_ID"

# 1. Criar plano padrão (populado com ~90 contas)
curl -s -X POST "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas/padrao?nome=Plano%20Padrão%202026" \
  -H "Authorization: Bearer $TOKEN" | jq

# 2. Listar planos
curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq

# 3. Pegar o ID do plano e listar contas em árvore
PLANO_ID=$(curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

curl -s "http://localhost:3000/api/v1/planos/$PLANO_ID/contas" \
  -H "Authorization: Bearer $TOKEN" | jq '.[0:3]'

# 4. Criar centro de custo
curl -s -X POST "http://localhost:3000/api/v1/centros-custo" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"empresaId\":\"$EMPRESA_ID\",\"codigo\":\"ADM\",\"nome\":\"Administrativo\"}" | jq