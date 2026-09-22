TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimar@teste2.com","senha":"SenhaForte@123"}' \
  | jq -r '.accessToken')

echo "Token: $TOKEN"