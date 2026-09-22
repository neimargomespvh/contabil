# 1. Restaurar variáveis
source /tmp/contabil-env.sh

# 2. Verificar
echo "TOKEN: ${TOKEN:0:40}..."
echo "Tamanho: ${#TOKEN}"
echo "EMPRESA_ID: $EMPRESA_ID"

# 3. Se o token estiver vazio, refazer login
if [ "${#TOKEN}" -lt 100 ]; then
  echo "Token vazio, refazendo login..."
  export TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}' \
    | jq -r '.accessToken')
  echo "Novo TOKEN: ${TOKEN:0:40}..."
  echo "Tamanho: ${#TOKEN}"
fi

# 4. Testar duplicidade
XML_JSON=$(cat /tmp/nfe-teste.xml | jq -Rs .)

echo ""
echo "=== TESTANDO DUPLICIDADE ==="
curl -s -X POST http://localhost:3000/api/v1/documentos-fiscais/importar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"empresaId\":\"$EMPRESA_ID\",\"xml\":$XML_JSON}" | jq