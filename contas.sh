# ============================================================
# PASSO 4 — CONTAS DO PLANO
# ============================================================
echo "=== BUSCANDO CONTAS ==="

CONTA_ESTOQUE=$(curl -s "http://localhost:3000/api/v1/planos/$PLANO_ID/contas" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.. | objects | select(.codigo=="1.1.3.01") | .id' | head -1)

CONTA_FORNECEDOR=$(curl -s "http://localhost:3000/api/v1/planos/$PLANO_ID/contas" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.. | objects | select(.codigo=="2.1.1.01") | .id' | head -1)

echo "CONTA_ESTOQUE:    [$CONTA_ESTOQUE]"
echo "CONTA_FORNECEDOR: [$CONTA_FORNECEDOR]"

# Validar
if [ -z "$CONTA_ESTOQUE" ] || [ "$CONTA_ESTOQUE" = "null" ]; then
  echo "❌ Conta 1.1.3.01 não encontrada. Veja as contas:"
  curl -s "http://localhost:3000/api/v1/planos/$PLANO_ID/contas" \
    -H "Authorization: Bearer $TOKEN" | jq '.. | objects | select(.codigo != null) | {codigo, nome, tipo}'
fi