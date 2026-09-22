# ============================================================
# PASSO 3 — PLANO DE CONTAS
# ============================================================
echo "=== PLANOS DE CONTA EXISTENTES ==="
curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq

# Tentar pegar o primeiro plano
PLANO_ID=$(curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

echo "PLANO_ID: [$PLANO_ID]"

# Se vazio, criar plano padrão
if [ "$PLANO_ID" = "null" ] || [ -z "$PLANO_ID" ]; then
  echo "=== CRIANDO PLANO PADRÃO ==="
  curl -X POST "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas/padrao?nome=Plano%20Padr%C3%A3o" \
    -H "Authorization: Bearer $TOKEN" | jq

  # Re-consultar
  PLANO_ID=$(curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

  echo "PLANO_ID agora: [$PLANO_ID]"
fi