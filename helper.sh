cat > ~/.contabil <<'EOF'
#!/usr/bin/env bash
# Carrega credenciais e faz login automaticamente

export CONTABIL_EMAIL="neimargomes@gmail.com"
export CONTABIL_SENHA="200644ng"

export TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$CONTABIL_EMAIL\",\"senha\":\"$CONTABIL_SENHA\"}" \
  | jq -r '.accessToken')

# Carregar IDs se existirem
if [ -f /tmp/contabil-env.sh ]; then
  source /tmp/contabil-env.sh
  # Reexportar o token fresco (o antigo pode estar expirado)
  export TOKEN
fi

echo "✅ TOKEN: ${TOKEN:0:40}... (${#TOKEN} caracteres)"
echo "✅ EMPRESA_ID: $EMPRESA_ID"
echo "✅ PLANO_ID: $PLANO_ID"
EOF

chmod +x ~/.contabil
echo "✅ Helper criado. Use com: source ~/.contabil"