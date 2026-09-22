#!/usr/bin/env bash
# ============================================================
# Sistema Contábil — Script de Inicialização
# Uso: ./contabil-start.sh
# ============================================================

set -e

PROJETO_DIR="/home/neimar/Projetos/Contabil"
API_PORT=3000
API_URL="http://localhost:${API_PORT}/api/v1"

# Cores
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${VERDE}[OK]${NC} $1"; }
aviso()  { echo -e "${AMARELO}[..]${NC} $1"; }
erro()   { echo -e "${VERMELHO}[ERRO]${NC} $1"; }
titulo() { echo -e "\n${AZUL}═══ $1 ═══${NC}"; }

# ============================================================
# 1. VERIFICAR DOCKER
# ============================================================
titulo "1/6 Docker"

if ! docker info >/dev/null 2>&1; then
  aviso "Docker não está rodando. Iniciando..."
  sudo systemctl start docker
  sleep 5
fi

if ! docker info >/dev/null 2>&1; then
  erro "Docker não iniciou. Verifique com: sudo systemctl status docker"
  exit 1
fi
log "Docker ativo"

# ============================================================
# 2. SUBIR CONTAINERS
# ============================================================
titulo "2/6 Containers (Postgres, Redis, MinIO)"

cd "$PROJETO_DIR"

# Subir se não estiverem rodando
if ! docker compose ps --status running | grep -q postgres; then
  aviso "Subindo containers..."
  docker compose up -d
else
  log "Containers já rodando"
fi

# Aguardar postgres ficar saudável (máx 60s)
aviso "Aguardando Postgres ficar pronto..."
for i in $(seq 1 30); do
  if docker exec contabil-postgres pg_isready -U postgres -d contabil >/dev/null 2>&1; then
    log "Postgres pronto"
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    erro "Postgres não ficou pronto em 60s"
    docker compose logs postgres | tail -20
    exit 1
  fi
done

# Aguardar Redis
aviso "Aguardando Redis..."
for i in $(seq 1 15); do
  if docker exec contabil-redis redis-cli ping >/dev/null 2>&1; then
    log "Redis pronto"
    break
  fi
  sleep 1
done

# ============================================================
# 3. VERIFICAR API
# ============================================================
titulo "3/6 API NestJS"

if curl -s "${API_URL}/health" >/dev/null 2>&1; then
  log "API já está rodando"
  API_RODANDO=true
else
  API_RODANDO=false
fi

if [ "$API_RODANDO" = false ]; then
  aviso "Iniciando API em background..."
  mkdir -p /tmp/contabil-logs
  
  # Verificar se precisa compilar
  if [ ! -d "dist" ] || [ -z "$(ls -A dist 2>/dev/null)" ]; then
    aviso "Compilando projeto (primeira execução)..."
    npm run build
  fi
  
  # Iniciar em background
  nohup npm run dev > /tmp/contabil-logs/api.log 2>&1 &
  echo $! > /tmp/contabil-logs/api.pid
  log "API iniciada (PID: $(cat /tmp/contabil-logs/api.pid))"
  
  # Aguardar API responder (máx 45s)
  aviso "Aguardando API responder..."
  for i in $(seq 1 45); do
    if curl -s "${API_URL}/health" >/dev/null 2>&1; then
      log "API respondendo"
      break
    fi
    sleep 1
    if [ "$i" -eq 45 ]; then
      erro "API não respondeu em 45s. Verifique: tail -f /tmp/contabil-logs/api.log"
      exit 1
    fi
  done
fi

# ============================================================
# 4. VERIFICAR SAÚDE
# ============================================================
titulo "4/6 Health Check"

HEALTH=$(curl -s "${API_URL}/health")
STATUS=$(echo "$HEALTH" | jq -r '.status' 2>/dev/null || echo "erro")

if [ "$STATUS" = "healthy" ]; then
  log "API saudável"
  echo "$HEALTH" | jq
else
  aviso "API respondeu, mas status: $STATUS"
  echo "$HEALTH" | jq 2>/dev/null || echo "$HEALTH"
fi

# ============================================================
# 5. LOGIN AUTOMÁTICO
# ============================================================
titulo "5/6 Autenticação"

# Credenciais (salvas no primeiro uso)
CREDS_FILE="$HOME/.contabil-creds"

if [ ! -f "$CREDS_FILE" ]; then
  aviso "Credenciais não encontradas. Configurando pela primeira vez..."
  read -p "Email: " CONTABIL_EMAIL
  read -s -p "Senha: " CONTABIL_SENHA
  echo ""
  
  cat > "$CREDS_FILE" <<EOF
export CONTABIL_EMAIL="$CONTABIL_EMAIL"
export CONTABIL_SENHA="$CONTABIL_SENHA"
EOF
  chmod 600 "$CREDS_FILE"
  log "Credenciais salvas em $CREDS_FILE"
fi

source "$CREDS_FILE"

TOKEN=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$CONTABIL_EMAIL\",\"senha\":\"$CONTABIL_SENHA\"}" \
  | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ] || [ "${#TOKEN}" -lt 100 ]; then
  erro "Login falhou. Verifique as credenciais em $CREDS_FILE"
  erro "Para recadastrar: rm $CREDS_FILE && ./contabil-start.sh"
  exit 1
fi

log "Login OK — token de ${#TOKEN} caracteres"

# Carregar IDs existentes (se arquivo existir)
ENV_FILE="/tmp/contabil-env.sh"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

# Salvar token fresco + credenciais
cat > "$ENV_FILE" <<EOF
export TOKEN="$TOKEN"
export EMPRESA_ID="$EMPRESA_ID"
export PLANO_ID="$PLANO_ID"
export CONTA_ESTOQUE="$CONTA_ESTOQUE"
export CONTA_FORNECEDOR="$CONTA_FORNECEDOR"
export CONTABIL_EMAIL="$CONTABIL_EMAIL"
export CONTABIL_SENHA="$CONTABIL_SENHA"
EOF

# ============================================================
# 6. RESUMO
# ============================================================
titulo "6/6 Sistema pronto"

echo ""
echo "  🐘 Postgres:  localhost:5432"
echo "  🔴 Redis:     localhost:6379"
echo "  📦 MinIO:     http://localhost:9001  (minio / minio123)"
echo "  🚀 API:       ${API_URL}"
echo "  📚 Swagger:   http://localhost:${API_PORT}/docs"
echo ""

if [ -n "$EMPRESA_ID" ] && [ "$EMPRESA_ID" != "null" ]; then
  echo "  📌 Empresa ativa:   $EMPRESA_ID"
  echo "  📌 Plano de contas: $PLANO_ID"
fi

echo ""
log "Para usar em outros terminais: source $ENV_FILE"
log "Para parar tudo: docker compose down && kill \$(cat /tmp/contabil-logs/api.pid)"
echo ""