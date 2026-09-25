#!/usr/bin/env bash
set -e

API="http://localhost:3000/api/v1"
EMAIL="neimargomes@gmail.com"
SENHA="200644ng"

echo "🔐 Fazendo login..."
LOGIN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"senha\":\"$SENHA\"}")

TOKEN=$(echo "$LOGIN" | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Falha no login:"
  echo "$LOGIN" | jq
  exit 1
fi

echo "✅ Token obtido: ${TOKEN:0:40}..."

echo ""
echo "📋 Listando empresas..."
EMPRESAS=$(curl -s "$API/empresas" -H "Authorization: Bearer $TOKEN")
echo "$EMPRESAS" | jq

EMPRESA_ID=$(echo "$EMPRESAS" | jq -r '.data[0].id // .[0].id // empty')

if [ -z "$EMPRESA_ID" ]; then
  echo "⚠️  Nenhuma empresa cadastrada"
  exit 0
fi

echo ""
echo "📒 Listando lançamentos da empresa $EMPRESA_ID..."
curl -s "$API/lancamentos?empresaId=$EMPRESA_ID&page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq