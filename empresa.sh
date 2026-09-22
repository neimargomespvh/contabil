echo "=== CRIANDO EMPRESA ==="
curl -X POST http://localhost:3000/api/v1/empresas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "razaoSocial": "Empresa Teste LTDA",
    "cnpj": "11222333000181",
    "regimeTributario": "SIMPLES",
    "anexoSimples": "I"
  }' | jq

# Re-consultar
EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')

echo "EMPRESA_ID agora: [$EMPRESA_ID]"