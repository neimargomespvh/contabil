#!/usr/bin/env bash
source /tmp/contabil-env.sh

echo "=== 1. Login ==="
export TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}' \
  | jq -r '.accessToken')

echo "TOKEN: ${TOKEN:0:40}... (${#TOKEN} chars)"

echo ""
echo "=== 2. Verificar bancos ==="
BANCOS_COUNT=$(docker exec -i contabil-postgres psql -U postgres -d contabil -t -c \
  "SELECT COUNT(*) FROM bancos;" | tr -d ' ')

echo "Total de bancos: $BANCOS_COUNT"

if [ "$BANCOS_COUNT" -lt 8 ]; then
  echo "⚠️  Poucos bancos. Rodando seed..."
  npx prisma db seed
fi

echo ""
echo "=== 3. Verificar empresas ==="
export EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')

echo "EMPRESA_ID: [$EMPRESA_ID]"

if [ "$EMPRESA_ID" = "null" ] || [ -z "$EMPRESA_ID" ]; then
  echo "⚠️  Nenhuma empresa. Criando..."
  curl -s -X POST http://localhost:3000/api/v1/empresas \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "razaoSocial": "Empresa Teste LTDA",
      "cnpj": "11222333000181",
      "regimeTributario": "SIMPLES",
      "anexoSimples": "I"
    }' | jq

  export EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')
  echo "EMPRESA_ID criado: $EMPRESA_ID"
fi

echo ""
echo "=== 4. Criar conta bancária ==="
RESP=$(curl -s -X POST http://localhost:3000/api/v1/contas-bancarias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"empresaId\": \"$EMPRESA_ID\",
    \"bancoCodigo\": \"341\",
    \"agencia\": \"1234\",
    \"numeroConta\": \"56789\",
    \"tipo\": \"CORRENTE\"
  }")

echo "$RESP" | jq

export CONTA_BANCARIA_ID=$(echo "$RESP" | jq -r '.id')
echo "CONTA_BANCARIA_ID: [$CONTA_BANCARIA_ID]"

if [ "$CONTA_BANCARIA_ID" = "null" ] || [ -z "$CONTA_BANCARIA_ID" ]; then
  echo "❌ Falha. Veja a resposta acima para o motivo."
  exit 1
fi

echo ""
echo "=== 5. Salvar variáveis ==="
cat > /tmp/contabil-env.sh <<EOF
export TOKEN="$TOKEN"
export EMPRESA_ID="$EMPRESA_ID"
export PLANO_ID="$PLANO_ID"
export CONTA_ESTOQUE="$CONTA_ESTOQUE"
export CONTA_FORNECEDOR="$CONTA_FORNECEDOR"
export CONTA_BANCARIA_ID="$CONTA_BANCARIA_ID"
export CONTABIL_EMAIL="neimargomes@gmail.com"
export CONTABIL_SENHA="200644ng"
EOF

echo "✅ Variáveis atualizadas"

echo ""
echo "=== 6. Importar OFX ==="
cat > /tmp/extrato.ofx <<'OFXEOF'
OFXHEADER:100
DATA:OFXSGML
VERSION:102

<OFX>
<BANKMSGSRSV1>
<STMTTRNRS>
<STMTRS>
<BANKACCTFROM>
<BANKID>341
<ACCTID>56789
<BRANCHID>1234
</BANKACCTFROM>
<BANKTRANLIST>
<DTSTART>20260901
<DTEND>20260930
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260920
<TRNAMT>1000.00
<MEMO>RECEBIMENTO CLIENTE XYZ
</STMTTRN>
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260915
<TRNAMT>-150.50
<MEMO>PAGAMENTO FORNECEDOR ABC
</STMTTRN>
</BANKTRANLIST>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>
</OFX>
OFXEOF

OFX_JSON=$(cat /tmp/extrato.ofx | jq -Rs .)

curl -s -X POST http://localhost:3000/api/v1/conciliacao/importar-ofx \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"contaBancariaId\": \"$CONTA_BANCARIA_ID\",
    \"conteudo\": $OFX_JSON
  }" | jq

echo ""
echo "=== 7. Dashboard ==="
curl -s "http://localhost:3000/api/v1/conciliacao/dashboard?contaBancariaId=$CONTA_BANCARIA_ID" \
  -H "Authorization: Bearer $TOKEN" | jq