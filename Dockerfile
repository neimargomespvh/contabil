# ═══════════════════════════════════════════════════════
# BACKEND — NestJS + Prisma (multi-stage)
# ═══════════════════════════════════════════════════════

# ─── STAGE 1: builder ───
FROM node:20-alpine AS builder

WORKDIR /app

RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/
COPY tsconfig*.json nest-cli.json ./

RUN npm ci

COPY src ./src

RUN npx prisma generate

# CRÍTICO: limpar build residual
RUN rm -rf dist/ *.tsbuildinfo

RUN npm run build

# Validação explícita
RUN test -f /app/dist/main.js || (echo "❌ /app/dist/main.js NÃO EXISTE" && ls -la /app/dist/ && exit 1)

# ─── STAGE 2: runner ───
FROM node:20-alpine AS runner

WORKDIR /app

RUN apk add --no-cache openssl curl dumb-init

ENV NODE_ENV=production \
    PORT=3000

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci --omit=dev \
 && npx prisma generate \
 && npm cache clean --force

COPY --from=builder /app/dist ./dist

RUN addgroup -g 1001 -S nodejs \
 && adduser -S nestjs -u 1001 -G nodejs \
 && chown -R nestjs:nodejs /app

USER nestjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:3000/api/v1/health || exit 1

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main"]
