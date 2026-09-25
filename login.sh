TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}' \
  | jq -r '.data.accessToken')

echo "Token: ${TOKEN:0:40}..."

echo ""
echo "═══ EMPRESAS (deve vir com success:true e data) ═══"
curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq