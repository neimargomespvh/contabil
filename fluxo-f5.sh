#!/usr/bin/env bash
set -e

# Carregar credenciais
source /tmp/contabil-env.sh

echo "============================================"
echo "1️⃣  CRIAR EMPRESA"
echo "============================================"
EMPRESA_RESP=$(curl -s -X POST http://localhost:3000/api/v1/empresas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "razaoSocial": "Empresa Teste LTDA",
    "cnpj": "11222333000181",
    "regimeTributario": "SIMPLES",
    "anexoSimples": "I"
  }')

echo "$EMPRESA_RESP" | jq

# Se já existia, pega a primeira
EMPRESA_ID=$(curl -s "http://localhost:3000/api/v1/empresas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')

if [ "$EMPRESA_ID" = "null" ] || [ -z "$EMPRESA_ID" ]; then
  echo "❌ Não foi possível obter empresa"
  exit 1
fi

echo "✅ EMPRESA_ID: $EMPRESA_ID"

echo ""
echo "============================================"
echo "2️⃣  CRIAR PLANO PADRÃO"
echo "============================================"
curl -s -X POST "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas/padrao" \
  -H "Authorization: Bearer $TOKEN" | jq

PLANO_ID=$(curl -s "http://localhost:3000/api/v1/empresas/$EMPRESA_ID/plano-contas" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

echo "✅ PLANO_ID: $PLANO_ID"

echo ""
echo "============================================"
echo "3️⃣  BUSCAR CONTAS"
echo "============================================"
CONTA_ESTOQUE=$(curl -s "http://localhost:3000/api/v1/planos/$PLANO_ID/contas" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.. | objects | select(.codigo=="1.1.3.01") | .id' | head -1)

CONTA_FORNECEDOR=$(curl -s "http://localhost:3000/api/v1/planos/$PLANO_ID/contas" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.. | objects | select(.codigo=="2.1.1.01") | .id' | head -1)

echo "✅ CONTA_ESTOQUE:    $CONTA_ESTOQUE"
echo "✅ CONTA_FORNECEDOR: $CONTA_FORNECEDOR"

echo ""
echo "============================================"
echo "4️⃣  INSERIR REGRA DE CONTABILIZAÇÃO"
echo "============================================"

# Deletar regra antiga se existir (idempotente)
docker exec -i contabil-postgres psql -U postgres -d contabil -c \
  "DELETE FROM regras_contabilizacao WHERE empresa_id = '$EMPRESA_ID';" > /dev/null

docker exec -i contabil-postgres psql -U postgres -d contabil <<SQL
INSERT INTO regras_contabilizacao (
  id, tenant_id, empresa_id, nome, prioridade, condicao,
  conta_debito_id, conta_credito_id, historico_template, status, created_at
)
SELECT
  gen_random_uuid(),
  e.tenant_id,
  e.id,
  'Compra de mercadoria — CFOP 5102/6102',
  1,
  '{"tipo":"NFE","cfop":["5102","6102"]}'::jsonb,
  '$CONTA_ESTOQUE',
  '$CONTA_FORNECEDOR',
  'NF {numero}/{serie} - {emitente}',
  'ATIVO',
  NOW()
FROM empresas e
WHERE e.id = '$EMPRESA_ID';
SQL

echo ""
echo "Regra criada:"
docker exec -i contabil-postgres psql -U postgres -d contabil -c \
  "SELECT nome, prioridade, condicao, status FROM regras_contabilizacao WHERE empresa_id = '$EMPRESA_ID';"

echo ""
echo "============================================"
echo "5️⃣  CRIAR XML DE TESTE"
echo "============================================"

cat > /tmp/nfe-teste.xml <<'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<nfeProc versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">
  <NFe>
    <infNFe Id="NFe35240612345678901234550010000001231234567890" versao="4.00">
      <ide>
        <cUF>35</cUF>
        <nNF>123</nNF>
        <serie>1</serie>
        <mod>55</mod>
        <dhEmi>2026-09-15T10:00:00-03:00</dhEmi>
      </ide>
      <emit>
        <CNPJ>12345678901234</CNPJ>
        <xNome>Fornecedor Teste LTDA</xNome>
      </emit>
      <dest>
        <CNPJ>98765432109876</CNPJ>
        <xNome>Empresa Cliente</xNome>
      </dest>
      <det nItem="1">
        <prod>
          <cProd>001</cProd>
          <xProd>Produto Teste</xProd>
          <NCM>12345678</NCM>
          <CFOP>5102</CFOP>
          <qCom>10</qCom>
          <vUnCom>100.00</vUnCom>
          <vProd>1000.00</vProd>
        </prod>
        <imposto>
          <ICMS>
            <ICMS00>
              <vICMS>180.00</vICMS>
              <pICMS>18.00</pICMS>
            </ICMS00>
          </ICMS>
        </imposto>
      </det>
      <total>
        <ICMSTot>
          <vNF>1000.00</vNF>
          <vICMS>180.00</vICMS>
        </ICMSTot>
      </total>
    </infNFe>
  </NFe>
</nfeProc>
XMLEOF

echo "✅ XML criado em /tmp/nfe-teste.xml"

echo ""
echo "============================================"
echo "6️⃣  IMPORTAR XML"
echo "============================================"

XML_JSON=$(cat /tmp/nfe-teste.xml | jq -Rs .)

curl -s -X POST http://localhost:3000/api/v1/documentos-fiscais/importar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"empresaId\": \"$EMPRESA_ID\",
    \"xml\": $XML_JSON,
    \"contabilizarAutomaticamente\": true
  }" | jq

echo ""
echo "============================================"
echo "7️⃣  VERIFICAR LANÇAMENTO NO BANCO"
echo "============================================"
docker exec -i contabil-postgres psql -U postgres -d contabil -c "
SELECT
  l.historico,
  l.valor_total,
  c.codigo AS conta,
  p.tipo,
  p.valor
FROM lancamentos l
JOIN partidas p ON p.lancamento_id = l.id
JOIN contas c ON c.id = p.conta_id
WHERE l.documento_ref = '35240612345678901234550010000001231234567890';
"

echo ""
echo "============================================"
echo "8️⃣  SALVAR VARIÁVEIS"
echo "============================================"

cat > /tmp/contabil-env.sh <<EOF
export TOKEN="$TOKEN"
export EMPRESA_ID="$EMPRESA_ID"
export PLANO_ID="$PLANO_ID"
export CONTA_ESTOQUE="$CONTA_ESTOQUE"
export CONTA_FORNECEDOR="$CONTA_FORNECEDOR"
export CONTABIL_EMAIL="neimargomes@gmail.com"
export CONTABIL_SENHA="200644ng"
EOF

echo "✅ Variáveis salvas em /tmp/contabil-env.sh"
echo ""
echo "🎉 Fluxo completo finalizado!"