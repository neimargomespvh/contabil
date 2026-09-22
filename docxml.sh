cat > /tmp/nfe-teste.xml <<'XML'
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
XML

XML_CONTENT=$(cat /tmp/nfe-teste.xml | jq -Rs .)

curl -X POST http://localhost:3000/api/v1/documentos-fiscais/importar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"empresaId\": \"$EMPRESA_ID\",
    \"xml\": $XML_CONTENT,
    \"contabilizarAutomaticamente\": true
  }" | jq