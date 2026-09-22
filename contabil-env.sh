source /tmp/contabil-env.sh

# Garantir que o token está fresco
export TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"neimargomes@gmail.com","senha":"200644ng"}' \
  | jq -r '.accessToken')

# 1. Criar conta bancária
CONTA_BANCARIA_ID=$(curl -s -X POST http://localhost:3000/api/v1/contas-bancarias \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"empresaId\": \"$EMPRESA_ID\",
    \"bancoCodigo\": \"341\",
    \"agencia\": \"1234\",
    \"numeroConta\": \"56789\",
    \"tipo\": \"CORRENTE\"
  }" | jq -r '.id')

echo "Conta bancária: $CONTA_BANCARIA_ID"

# 2. Criar OFX de teste
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

# 3. Importar OFX
OFX_JSON=$(cat /tmp/extrato.ofx | jq -Rs .)

curl -s -X POST http://localhost:3000/api/v1/conciliacao/importar-ofx \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"contaBancariaId\": \"$CONTA_BANCARIA_ID\",
    \"conteudo\": $OFX_JSON
  }" | jq

# 4. Listar extratos
curl -s "http://localhost:3000/api/v1/conciliacao/extratos?contaBancariaId=$CONTA_BANCARIA_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.meta'

# 5. Dashboard
curl -s "http://localhost:3000/api/v1/conciliacao/dashboard?contaBancariaId=$CONTA_BANCARIA_ID" \
  -H "Authorization: Bearer $TOKEN" | jq

# 6. Testar CSV
cat > /tmp/extrato.csv <<'CSVEOF'
Data;Descrição;Valor;Documento
22/09/2026;PIX RECEBIDO;500,00;PIX123
23/09/2026;TARIFA MENSAL;-29,90;
CSVEOF

CSV_JSON=$(cat /tmp/extrato.csv | jq -Rs .)

curl -s -X POST http://localhost:3000/api/v1/conciliacao/importar-csv \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"contaBancariaId\": \"$CONTA_BANCARIA_ID\",
    \"conteudo\": $CSV_JSON,
    \"mapeamento\": {
      \"separador\": \";\",
      \"data\": \"Data\",
      \"descricao\": \"Descrição\",
      \"valor\": \"Valor\",
      \"documento\": \"Documento\",
      \"formatoData\": \"DD/MM/YYYY\",
      \"decimalVirgula\": true
    }
  }" | jq