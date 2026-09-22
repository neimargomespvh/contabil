# Sistema Contábil

Sistema contábil multitenant para escritórios de contabilidade.

## Stack

- **Backend:** NestJS 10 + TypeScript
- **Banco:** PostgreSQL 16 + Prisma
- **Cache/Filas:** Redis + BullMQ
- **Storage:** AWS S3 / MinIO
- **Auth:** JWT + Refresh Token + RBAC

## Módulos implementados (Fase 1 - MVP)

- [x] Autenticação e segurança (JWT, RBAC, multitenancy)
- [x] Cadastro de empresas e sócios
- [x] Plano de contas hierárquico
- [x] Lançamentos contábeis (partidas dobradas)
- [x] Estorno de lançamento
- [x] Centros de custo
- [ ] Importação de XML de NFe
- [ ] Conciliação bancária
- [ ] Apuração tributária
- [ ] Relatórios

## Como rodar

### Pré-requisitos

- Node.js 20+
- Docker e Docker Compose
- PostgreSQL 16 (via Docker)

### Setup

```bash
# 1. Instalar dependências
npm install

# 2. Subir infraestrutura
docker compose up -d

# 3. Configurar variáveis de ambiente
cp .env.example .env
# Edite .env conforme necessário

# 4. Rodar migrations
npx prisma migrate dev

# 5. Popular banco
npx prisma db seed

# 6. Iniciar em modo dev
npm run dev