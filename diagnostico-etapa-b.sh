cat > /tmp/diagnostico-etapa-b.sh <<'SCRIPT'
#!/usr/bin/env bash
cd ~/Projetos/Contabil

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

check() {
  local label="$1"; local file="$2"; local pattern="$3"
  if [ ! -f "$file" ]; then
    echo -e "${RED}✗ FALTA ARQUIVO${NC} $file"
    return
  fi
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} $label"
  else
    echo -e "${RED}✗${NC} $label  ${YELLOW}(padrão '$pattern' não encontrado em $file)${NC}"
  fi
}

echo "══════════════════════════════════════════════════════"
echo "DIAGNÓSTICO — Completude da Etapa B"
echo "══════════════════════════════════════════════════════"
echo ""
echo "── B2: Parsers ──"

check "interfaces tem DocumentoFiscalParseado" \
  src/modules/documentos-fiscais/parsers/interfaces.ts \
  "DocumentoFiscalParseado"

check "interfaces tem XmlMalformadoError" \
  src/modules/documentos-fiscais/parsers/interfaces.ts \
  "XmlMalformadoError"

check "interfaces tem ChaveInvalidaError" \
  src/modules/documentos-fiscais/parsers/interfaces.ts \
  "ChaveInvalidaError"

check "nfe.parser tem método parse" \
  src/modules/documentos-fiscais/parsers/nfe.parser.ts \
  "async parse"

check "nfe.parser detecta cancelamento (situacao)" \
  src/modules/documentos-fiscais/parsers/nfe.parser.ts \
  "CANCELADA\|situacao"

check "nfce.parser existe e estende NFe" \
  src/modules/documentos-fiscais/parsers/nfce.parser.ts \
  "NfeParser\|NFCE"

check "cte.parser existe" \
  src/modules/documentos-fiscais/parsers/cte.parser.ts \
  "CTE\|infCte"

check "nfse.parser existe" \
  src/modules/documentos-fiscais/parsers/nfse.parser.ts \
  "NFSE\|CompNfse"

check "dispatcher documento-fiscal.parser existe" \
  src/modules/documentos-fiscais/parsers/documento-fiscal.parser.ts \
  "class DocumentoFiscalParser"

echo ""
echo "── B3: Validação ──"

check "chave-nfe.validator tem calcularDv" \
  src/modules/documentos-fiscais/validators/chave-nfe.validator.ts \
  "calcularDv"

check "chave-nfe.validator valida 44 dígitos" \
  src/modules/documentos-fiscais/validators/chave-nfe.validator.ts \
  "44\|\\^\\\\d{44}"

echo ""
echo "── B3: S3 ──"

check "s3.service tem uploadXml" \
  src/infra/s3/s3.service.ts \
  "uploadXml\|PutObject"

check "s3.service tem getObject" \
  src/infra/s3/s3.service.ts \
  "getObject\|GetObject"

check "s3.service calcula SHA-256" \
  src/infra/s3/s3.service.ts \
  "sha256\|createHash"

echo ""
echo "── B4: DTOs ──"

check "importar-xml.dto existe" \
  src/modules/documentos-fiscais/dto/importar-xml.dto.ts \
  "ImportarXmlDto"

check "filter-documento.dto tem paginação" \
  src/modules/documentos-fiscais/dto/filter-documento.dto.ts \
  "page\|limit"

echo ""
echo "── B5: Serviços ──"

check "documentos-fiscais.service tem importar()" \
  src/modules/documentos-fiscais/documentos-fiscais.service.ts \
  "async importar"

check "documentos-fiscais.service tem importarLote()" \
  src/modules/documentos-fiscais/documentos-fiscais.service.ts \
  "importarLote"

check "contabilizacao.service tem contabilizar()" \
  src/modules/documentos-fiscais/services/contabilizacao.service.ts \
  "async contabilizar"

check "contabilizacao.service busca regras" \
  src/modules/documentos-fiscais/services/contabilizacao.service.ts \
  "encontrarRegra\|regraContabilizacao"

echo ""
echo "── B7: Controller ──"

check "controller tem POST /importar" \
  src/modules/documentos-fiscais/documentos-fiscais.controller.ts \
  "Post('importar')\|@Post"

check "controller tem upload de arquivo" \
  src/modules/documentos-fiscais/documentos-fiscais.controller.ts \
  "FileInterceptor\|UploadedFile"

check "controller tem upload-lote" \
  src/modules/documentos-fiscais/documentos-fiscais.controller.ts \
  "upload-lote\|FilesInterceptor"

echo ""
echo "── B8: Módulo ──"

check "módulo registra ContabilizacaoService" \
  src/modules/documentos-fiscais/documentos-fiscais.module.ts \
  "ContabilizacaoService"

echo ""
echo "══════════════════════════════════════════════════════"
echo "ARQUIVOS SUSPEITOS / LIXO"
echo "══════════════════════════════════════════════════════"
[ -f src/modules/documentos-fiscais/parsers/index2.ts ] && \
  echo -e "${YELLOW}⚠${NC}  parsers/index2.ts existe — provavelmente duplicado, pode remover"

echo ""
echo "══════════════════════════════════════════════════════"
echo "ARQUIVOS ESPERADOS QUE NÃO EXISTEM"
echo "══════════════════════════════════════════════════════"
for f in \
  src/modules/documentos-fiscais/documentos-fiscais.repository.ts \
  src/modules/documentos-fiscais/parsers/nfe.parser.spec.ts \
  src/modules/documentos-fiscais/services/xml-validator.service.ts
do
  [ ! -f "$f" ] && echo -e "${YELLOW}○${NC}  $f"
done
SCRIPT

chmod +x /tmp/diagnostico-etapa-b.sh
/tmp/diagnostico-etapa-b.sh