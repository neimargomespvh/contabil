source /tmp/contabil-env.sh
XML_JSON=$(cat /tmp/nfe-teste.xml | jq -Rs .)

curl -s -X POST http://localhost:3000/api/v1/documentos-fiscais/importar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"empresaId\":\"$EMPRESA_ID\",\"xml\":$XML_JSON}" | jq