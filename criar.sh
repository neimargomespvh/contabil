# 1. Criar empresa
echo "=== CRIANDO EMPRESA ==="
curl -s -X POST http://localhost:3000/api/v1/empresas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "razaoSocial": "Empresa Teste LTDA",
    "cnpj": "11222333000181",
    "regimeTributario": "SIMPLES",
    "anexoSimples": "I"
  }' | jq

# 2. Pegar ID
EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')
echo "EMPRESA_ID = [$EMPRESA_ID]"

# 3. Criar plano padrão
echo "=== CRIANDO PLANO ==="
curl -s -X POST "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas/padrao" \
  -H "Authorization: Bearer $TOKEN" | jq

# 4. Pegar ID do plano
PLANO_ID=$(curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
echo "PLANO_ID = [$PLANO_ID]"

# 5. Salvar em arquivo para não perder
cat > /tmp/contabil-env.sh <<EOF
export TOKEN="$TOKEN"
export EMPRESA_ID="$EMPRESA_ID"
export PLANO_ID="$PLANO_ID"
EOF

echo "✅ Variáveis salvas em /tmp/contabil-env.sh"