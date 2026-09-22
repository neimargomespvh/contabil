# Terminal 2: executar os comandos abaixo
cd /home/neimar/Projetos/Contabil

# 1. Login
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}' \
  | jq -r '.accessToken')

echo "TOKEN: ${TOKEN:0:40}..."

# 2. Empresa
EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')
echo "EMPRESA_ID: $EMPRESA_ID"

# 3. Plano de contas
PLANO_ID=$(curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
echo "PLANO_ID: $PLANO_ID"