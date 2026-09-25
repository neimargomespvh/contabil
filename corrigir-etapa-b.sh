#!/usr/bin/env bash
set -euo pipefail

cd ~/Projetos/Contabil

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}▶${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }

# ═══════════════════════════════════════════════════════
# 1. DIAGNÓSTICO
# ═══════════════════════════════════════════════════════
log "Verificando arquivos corrompidos..."

CORROMPIDOS=()
for f in \
  src/modules/documentos-fiscais/parsers/interfaces.ts \
  src/modules/documentos-fiscais/parsers/nfe.parser.ts \
  src/modules/documentos-fiscais/documentos-fiscais.controller.ts \
  src/modules/documentos-fiscais/services/importacao.service.ts
do
  if [ -f "$f" ] && head -1 "$f" | grep -q "^cat >"; then
    err "CORROMPIDO: $f"
    CORROMPIDOS+=("$f")
  elif [ -f "$f" ]; then
    ok "OK: $f"
  else
    warn "FALTA: $f"
  fi
done

echo ""

# ═══════════════════════════════════════════════════════
# 2. BACKUP
# ═══════════════════════════════════════════════════════
BACKUP_DIR=".backup/corrigir-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for f in "${CORROMPIDOS[@]}"; do
  mkdir -p "$BACKUP_DIR/$(dirname "$f")"
  cp "$f" "$BACKUP_DIR/$f"
done

ok "Backup dos corrompidos em: $BACKUP_DIR"

# ═══════════════════════════════════════════════════════
# 3. LIMPAR (remover as linhas de comando bash que foram coladas)
# ═══════════════════════════════════════════════════════
if [ ${#CORROMPIDOS[@]} -gt 0 ]; then
  log "Limpando arquivos corrompidos..."

  for f in "${CORROMPIDOS[@]}"; do
    # Encontrar a linha "EOF" e pegar tudo DEPOIS dela
    LINE_EOF=$(grep -n "^EOF$" "$f" | head -1 | cut -d: -f1)

    if [ -n "$LINE_EOF" ]; then
      # Pega da linha depois do EOF até o final
      tail -n +$((LINE_EOF + 1)) "$f" > "$f.tmp"
      mv "$f.tmp" "$f"
      ok "Limpo: $f (removidas $LINE_EOF linhas)"
    else
      warn "Não achei 'EOF' em $f — precisa restaurar do backup"
    fi
  done
fi

# ═══════════════════════════════════════════════════════
# 4. VERIFICAR
# ═══════════════════════════════════════════════════════
echo ""
log "Verificando estado final..."

for f in \
  src/modules/documentos-fiscais/parsers/interfaces.ts \
  src/modules/documentos-fiscais/parsers/nfe.parser.ts \
  src/modules/documentos-fiscais/documentos-fiscais.controller.ts \
  src/modules/documentos-fiscais/services/importacao.service.ts
do
  if [ -f "$f" ]; then
    PRIMEIRA=$(head -1 "$f")
    if echo "$PRIMEIRA" | grep -q "^cat >"; then
      err "AINDA CORROMPIDO: $f"
    else
      ok "OK: $f"
      echo "     └─ $PRIMEIRA"
    fi
  fi
done

echo ""
ok "Pronto!"
echo ""
warn "Agora rode: npm run build 2>&1 | head -30"
