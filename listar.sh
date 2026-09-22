# ============================================================
# PASSO 2 — LISTAR EMPRESAS
# ============================================================
echo "=== EMPRESAS EXISTENTES ==="
curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq

# Pegar a primeira empresa
EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')

echo "EMPRESA_ID: [$EMPRESA_ID]"