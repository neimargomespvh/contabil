cd /home/neimar/Projetos/Contabil

cat > .env <<'EOF'
# App
NODE_ENV=development
PORT=3000
APP_NAME="Sistema Contábil"
APP_URL=http://localhost:3000

# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/contabil?schema=public"

# JWT (troque em produção!)
JWT_SECRET="dev-secret-nao-use-em-producao-0000000000000000000000000000"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET="dev-refresh-secret-nao-use-em-producao-000000000000000000"
JWT_REFRESH_EXPIRES_IN="7d"

# AWS / S3 (MinIO local)
AWS_REGION=sa-east-1
AWS_ENDPOINT=http://localhost:9000
AWS_FORCE_PATH_STYLE=true
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_S3_BUCKET=contabil-docs

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PREFIX=contabil:

# Rate limit
THROTTLE_TTL=60
THROTTLE_LIMIT=120

# CORS
CORS_ORIGIN=http://localhost:5173,http://localhost:3000
EOF

echo "✅ .env criado"