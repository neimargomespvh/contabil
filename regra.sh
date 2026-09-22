# ============================================================
# PASSO 1 — LOGIN
# ============================================================
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}')

echo "=== RESPOSTA DO LOGIN ==="
echo "$LOGIN_RESPONSE" | jq

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login falhou. Verifique o email/senha."
  echo "$LOGIN_RESPONSE" | jq
  exit 1
fi

echo "✅ TOKEN obtido: ${TOKEN:0:40}..."