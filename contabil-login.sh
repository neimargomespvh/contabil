#!/usr/bin/env bash
# Gera token fresco e salva em /tmp/contabil-env.sh

CONTABIL_EMAIL="${CONTABIL_EMAIL:-neimargomes@gmail.com}"
CONTABIL_SENHA="${CONTABIL_SENHA:-200644ng}"

TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$CONTABIL_EMAIL\",\"senha\":\"$CONTABIL_SENHA\"}" \
  | jq -r '.accessToken')

if [ "${#TOKEN}" -lt 100 ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login falhou. Verifique email/senha."
  exit 1
fi

# Carregar IDs existentes
if [ -f /tmp/contabil-env.sh ]; then
  source /tmp/contabil-env.sh
fi

# Salvar tudo atualizado
cat > /tmp/contabil-env.sh <<EOF
export TOKEN="$TOKEN"
export EMPRESA_ID="${EMPRESA_ID:-}"
export PLANO_ID="${PLANO_ID:-}"
export CONTABIL_EMAIL="$CONTABIL_EMAIL"
export CONTABIL_SENHA="$CONTABIL_SENHA"
EOF

echo "✅ Token atualizado: ${TOKEN:0:40}..."