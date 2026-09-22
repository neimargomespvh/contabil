-- CreateEnum
CREATE TYPE "TenantStatus" AS ENUM ('ATIVO', 'SUSPENSO', 'CANCELADO');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ATIVO', 'INATIVO');

-- CreateEnum
CREATE TYPE "EmpresaStatus" AS ENUM ('ATIVA', 'INATIVA', 'BAIXADA');

-- CreateEnum
CREATE TYPE "RegimeTributario" AS ENUM ('SIMPLES', 'PRESUMIDO', 'REAL', 'MEI');

-- CreateEnum
CREATE TYPE "AnexoSimples" AS ENUM ('I', 'II', 'III', 'IV', 'V');

-- CreateEnum
CREATE TYPE "NaturezaConta" AS ENUM ('ATIVO', 'PASSIVO', 'PATRIMONIO_LIQUIDO', 'RECEITA', 'DESPESA', 'CUSTO');

-- CreateEnum
CREATE TYPE "TipoConta" AS ENUM ('SINTETICA', 'ANALITICA');

-- CreateEnum
CREATE TYPE "StatusGenerico" AS ENUM ('ATIVO', 'INATIVO');

-- CreateEnum
CREATE TYPE "TipoLote" AS ENUM ('MANUAL', 'IMPORTACAO', 'AUTOMATICO');

-- CreateEnum
CREATE TYPE "StatusLote" AS ENUM ('RASCUNHO', 'CONFIRMADO', 'ESTORNADO');

-- CreateEnum
CREATE TYPE "StatusLancamento" AS ENUM ('ATIVO', 'ESTORNADO');

-- CreateEnum
CREATE TYPE "TipoPartida" AS ENUM ('D', 'C');

-- CreateEnum
CREATE TYPE "TipoDocumentoFiscal" AS ENUM ('NFE', 'NFCE', 'CTE', 'NFSE');

-- CreateEnum
CREATE TYPE "SituacaoDocumentoFiscal" AS ENUM ('AUTORIZADA', 'CANCELADA', 'DENEGADA', 'INUTILIZADA');

-- CreateEnum
CREATE TYPE "TipoContaBancaria" AS ENUM ('CORRENTE', 'POUPANCA', 'INVESTIMENTO');

-- CreateEnum
CREATE TYPE "OrigemImportacao" AS ENUM ('OFX', 'CSV', 'OPEN_FINANCE');

-- CreateEnum
CREATE TYPE "StatusApuracao" AS ENUM ('CALCULADA', 'TRANSMITIDA', 'PAGA');

-- CreateEnum
CREATE TYPE "TipoImposto" AS ENUM ('IRPJ', 'CSLL', 'PIS', 'COFINS', 'ISS', 'ICMS', 'DAS', 'IBS', 'CBS', 'IS');

-- CreateEnum
CREATE TYPE "TipoGuia" AS ENUM ('DAS', 'DARF', 'GPS', 'ISS', 'FGTS');

-- CreateEnum
CREATE TYPE "StatusGuia" AS ENUM ('GERADA', 'PAGA', 'VENCIDA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "TipoFechamento" AS ENUM ('ABERTO', 'FECHADO');

-- CreateEnum
CREATE TYPE "OperadorRegra" AS ENUM ('CONTEM', 'IGUAL', 'REGEX', 'COMECA_COM', 'TERMINA_COM');

-- CreateTable
CREATE TABLE "tenants" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nome" VARCHAR(200) NOT NULL,
    "cnpj" VARCHAR(14),
    "email" VARCHAR(200),
    "telefone" VARCHAR(20),
    "plano" VARCHAR(50),
    "status" "TenantStatus" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "nome" VARCHAR(200) NOT NULL,
    "email" VARCHAR(200) NOT NULL,
    "senha_hash" VARCHAR(255) NOT NULL,
    "mfa_secret" VARCHAR(255),
    "status" "UserStatus" NOT NULL DEFAULT 'ATIVO',
    "ultimo_acesso" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "nome" VARCHAR(50) NOT NULL,
    "descricao" VARCHAR(200),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "permissions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "codigo" VARCHAR(100) NOT NULL,
    "descricao" VARCHAR(200),

    CONSTRAINT "permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "role_permissions" (
    "role_id" UUID NOT NULL,
    "permission_id" UUID NOT NULL,

    CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id","permission_id")
);

-- CreateTable
CREATE TABLE "user_roles" (
    "user_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,

    CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id","role_id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "user_id" UUID,
    "entidade" VARCHAR(100) NOT NULL,
    "entidade_id" UUID,
    "acao" VARCHAR(20) NOT NULL,
    "payload_antes" JSONB,
    "payload_depois" JSONB,
    "ip" INET,
    "user_agent" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "empresas" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "razao_social" VARCHAR(200) NOT NULL,
    "nome_fantasia" VARCHAR(200),
    "cnpj" VARCHAR(14) NOT NULL,
    "inscricao_estadual" VARCHAR(20),
    "inscricao_municipal" VARCHAR(20),
    "regime_tributario" "RegimeTributario" NOT NULL,
    "anexo_simples" "AnexoSimples",
    "cnae_principal" VARCHAR(10),
    "cnaes_secundarios" JSONB,
    "data_abertura" DATE,
    "data_regime_atual" DATE,
    "endereco" JSONB,
    "email" VARCHAR(200),
    "telefone" VARCHAR(20),
    "responsavel_nome" VARCHAR(200),
    "responsavel_cpf" VARCHAR(11),
    "status" "EmpresaStatus" NOT NULL DEFAULT 'ATIVA',
    "observacoes" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "empresas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "socios" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "nome" VARCHAR(200) NOT NULL,
    "cpf" VARCHAR(11) NOT NULL,
    "participacao" DECIMAL(9,6) NOT NULL,
    "pro_labore" DECIMAL(18,2),
    "data_entrada" DATE,
    "data_saida" DATE,
    "status" VARCHAR(20) NOT NULL DEFAULT 'ativo',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "socios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plano_contas" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "nome" VARCHAR(200) NOT NULL,
    "versao" INTEGER NOT NULL,
    "vigencia_inicio" DATE NOT NULL,
    "vigencia_fim" DATE,
    "status" "StatusGenerico" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "plano_contas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contas" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "plano_contas_id" UUID NOT NULL,
    "conta_pai_id" UUID,
    "codigo" VARCHAR(30) NOT NULL,
    "nome" VARCHAR(200) NOT NULL,
    "natureza" "NaturezaConta" NOT NULL,
    "tipo" "TipoConta" NOT NULL,
    "grau" INTEGER NOT NULL,
    "aceita_lancamento" BOOLEAN NOT NULL,
    "dre_linha" VARCHAR(50),
    "status" "StatusGenerico" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "contas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "centros_custo" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "codigo" VARCHAR(30) NOT NULL,
    "nome" VARCHAR(200) NOT NULL,
    "status" "StatusGenerico" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "centros_custo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "historicos_padrao" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "codigo" VARCHAR(20),
    "descricao" VARCHAR(500) NOT NULL,
    "conta_debito_id" UUID,
    "conta_credito_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "historicos_padrao_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lotes_lancamento" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "tipo" "TipoLote" NOT NULL,
    "origem" VARCHAR(100),
    "competencia" DATE NOT NULL,
    "status" "StatusLote" NOT NULL DEFAULT 'RASCUNHO',
    "usuario_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "lotes_lancamento_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lancamentos" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "lote_id" UUID,
    "numero" BIGSERIAL NOT NULL,
    "data_lancamento" DATE NOT NULL,
    "competencia" DATE NOT NULL,
    "historico" VARCHAR(500) NOT NULL,
    "documento_ref" VARCHAR(100),
    "valor_total" DECIMAL(18,2) NOT NULL,
    "status" "StatusLancamento" NOT NULL DEFAULT 'ATIVO',
    "estorno_de_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "lancamentos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "partidas" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "lancamento_id" UUID NOT NULL,
    "conta_id" UUID NOT NULL,
    "centro_custo_id" UUID,
    "tipo" "TipoPartida" NOT NULL,
    "valor" DECIMAL(18,2) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "partidas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fechamentos_periodo" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "competencia" DATE NOT NULL,
    "status" "TipoFechamento" NOT NULL DEFAULT 'ABERTO',
    "fechado_por" UUID,
    "fechado_em" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "fechamentos_periodo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documentos_fiscais" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "tipo" "TipoDocumentoFiscal" NOT NULL,
    "chave_acesso" VARCHAR(44),
    "numero" VARCHAR(20),
    "serie" VARCHAR(10),
    "modelo" VARCHAR(5),
    "emitente_cnpj" VARCHAR(14),
    "emitente_nome" VARCHAR(200),
    "destinatario_cnpj" VARCHAR(14),
    "destinatario_nome" VARCHAR(200),
    "data_emissao" TIMESTAMPTZ(6) NOT NULL,
    "valor_total" DECIMAL(18,2) NOT NULL,
    "valor_icms" DECIMAL(18,2),
    "valor_pis" DECIMAL(18,2),
    "valor_cofins" DECIMAL(18,2),
    "valor_iss" DECIMAL(18,2),
    "valor_ibs" DECIMAL(18,2),
    "valor_cbs" DECIMAL(18,2),
    "valor_is" DECIMAL(18,2),
    "cfop_principal" VARCHAR(5),
    "ncm_principal" VARCHAR(10),
    "situacao" "SituacaoDocumentoFiscal" NOT NULL DEFAULT 'AUTORIZADA',
    "xml_s3_key" VARCHAR(500),
    "xml_hash" VARCHAR(64),
    "lancamento_id" UUID,
    "importado_em" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "documentos_fiscais_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "itens_documento_fiscal" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "documento_id" UUID NOT NULL,
    "numero_item" INTEGER NOT NULL,
    "codigo_produto" VARCHAR(60),
    "descricao" VARCHAR(500),
    "ncm" VARCHAR(10),
    "cfop" VARCHAR(5),
    "quantidade" DECIMAL(18,4),
    "valor_unitario" DECIMAL(18,6),
    "valor_total" DECIMAL(18,2),
    "valor_icms" DECIMAL(18,2),
    "aliquota_icms" DECIMAL(9,6),
    "valor_pis" DECIMAL(18,2),
    "valor_cofins" DECIMAL(18,2),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "itens_documento_fiscal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "regras_contabilizacao" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "nome" VARCHAR(200) NOT NULL,
    "prioridade" INTEGER NOT NULL,
    "condicao" JSONB NOT NULL,
    "conta_debito_id" UUID NOT NULL,
    "conta_credito_id" UUID NOT NULL,
    "historico_template" VARCHAR(500),
    "status" "StatusGenerico" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "regras_contabilizacao_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bancos" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "codigo" VARCHAR(10) NOT NULL,
    "nome" VARCHAR(100) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bancos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contas_bancarias" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "banco_id" UUID NOT NULL,
    "agencia" VARCHAR(20),
    "numero_conta" VARCHAR(30),
    "digito" VARCHAR(5),
    "tipo" "TipoContaBancaria" NOT NULL DEFAULT 'CORRENTE',
    "conta_contabil_id" UUID,
    "saldo_inicial" DECIMAL(18,2),
    "data_saldo_inicial" DATE,
    "status" "StatusGenerico" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "contas_bancarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "extratos_bancarios" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "conta_bancaria_id" UUID NOT NULL,
    "data_movimento" DATE NOT NULL,
    "descricao" VARCHAR(500),
    "documento" VARCHAR(100),
    "valor" DECIMAL(18,2) NOT NULL,
    "tipo" CHAR(1),
    "origem_importacao" "OrigemImportacao" NOT NULL,
    "hash_unico" VARCHAR(64) NOT NULL,
    "conciliado" BOOLEAN NOT NULL DEFAULT false,
    "lancamento_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "extratos_bancarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "regras_conciliacao" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "nome" VARCHAR(200),
    "campo" VARCHAR(50),
    "operador" "OperadorRegra",
    "valor_busca" VARCHAR(200),
    "conta_debito_id" UUID,
    "conta_credito_id" UUID,
    "prioridade" INTEGER,
    "status" "StatusGenerico" NOT NULL DEFAULT 'ATIVO',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "regras_conciliacao_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "apuracoes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "competencia" DATE NOT NULL,
    "regime" "RegimeTributario" NOT NULL,
    "anexo_simples" "AnexoSimples",
    "receita_bruta" DECIMAL(18,2),
    "base_calculo" DECIMAL(18,2),
    "aliquota" DECIMAL(9,6),
    "valor_devido" DECIMAL(18,2),
    "valor_deducao" DECIMAL(18,2),
    "valor_a_pagar" DECIMAL(18,2),
    "status" "StatusApuracao" NOT NULL DEFAULT 'CALCULADA',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "apuracoes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "apuracoes_impostos" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "apuracao_id" UUID NOT NULL,
    "imposto" "TipoImposto" NOT NULL,
    "base_calculo" DECIMAL(18,2),
    "aliquota" DECIMAL(9,6),
    "valor" DECIMAL(18,2),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "apuracoes_impostos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guias" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" UUID NOT NULL,
    "empresa_id" UUID NOT NULL,
    "apuracao_id" UUID,
    "tipo" "TipoGuia" NOT NULL,
    "codigo_receita" VARCHAR(10),
    "periodo_apuracao" DATE,
    "vencimento" DATE NOT NULL,
    "valor" DECIMAL(18,2) NOT NULL,
    "numero_documento" VARCHAR(50),
    "status" "StatusGuia" NOT NULL DEFAULT 'GERADA',
    "pdf_s3_key" VARCHAR(500),
    "pago_em" DATE,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tabelas_tributarias" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "regime" "RegimeTributario" NOT NULL,
    "anexo" "AnexoSimples",
    "faixa" INTEGER NOT NULL,
    "valor_inicial" DECIMAL(18,2),
    "valor_final" DECIMAL(18,2),
    "aliquota" DECIMAL(9,6),
    "parcela_deduzir" DECIMAL(18,2),
    "vigencia_inicio" DATE NOT NULL,
    "vigencia_fim" DATE,

    CONSTRAINT "tabelas_tributarias_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tenants_cnpj_key" ON "tenants"("cnpj");

-- CreateIndex
CREATE INDEX "users_tenant_id_idx" ON "users"("tenant_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_tenant_id_email_key" ON "users"("tenant_id", "email");

-- CreateIndex
CREATE UNIQUE INDEX "roles_tenant_id_nome_key" ON "roles"("tenant_id", "nome");

-- CreateIndex
CREATE UNIQUE INDEX "permissions_codigo_key" ON "permissions"("codigo");

-- CreateIndex
CREATE INDEX "audit_logs_tenant_id_entidade_entidade_id_idx" ON "audit_logs"("tenant_id", "entidade", "entidade_id");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- CreateIndex
CREATE INDEX "empresas_tenant_id_status_idx" ON "empresas"("tenant_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "empresas_tenant_id_cnpj_key" ON "empresas"("tenant_id", "cnpj");

-- CreateIndex
CREATE UNIQUE INDEX "socios_empresa_id_cpf_key" ON "socios"("empresa_id", "cpf");

-- CreateIndex
CREATE UNIQUE INDEX "plano_contas_empresa_id_versao_key" ON "plano_contas"("empresa_id", "versao");

-- CreateIndex
CREATE INDEX "contas_tenant_id_idx" ON "contas"("tenant_id");

-- CreateIndex
CREATE INDEX "contas_conta_pai_id_idx" ON "contas"("conta_pai_id");

-- CreateIndex
CREATE UNIQUE INDEX "contas_plano_contas_id_codigo_key" ON "contas"("plano_contas_id", "codigo");

-- CreateIndex
CREATE UNIQUE INDEX "centros_custo_empresa_id_codigo_key" ON "centros_custo"("empresa_id", "codigo");

-- CreateIndex
CREATE INDEX "lotes_lancamento_empresa_id_competencia_idx" ON "lotes_lancamento"("empresa_id", "competencia");

-- CreateIndex
CREATE INDEX "lotes_lancamento_status_idx" ON "lotes_lancamento"("status");

-- CreateIndex
CREATE INDEX "lancamentos_empresa_id_competencia_idx" ON "lancamentos"("empresa_id", "competencia");

-- CreateIndex
CREATE INDEX "lancamentos_empresa_id_data_lancamento_idx" ON "lancamentos"("empresa_id", "data_lancamento");

-- CreateIndex
CREATE INDEX "lancamentos_lote_id_idx" ON "lancamentos"("lote_id");

-- CreateIndex
CREATE INDEX "partidas_lancamento_id_idx" ON "partidas"("lancamento_id");

-- CreateIndex
CREATE INDEX "partidas_conta_id_idx" ON "partidas"("conta_id");

-- CreateIndex
CREATE INDEX "partidas_tenant_id_conta_id_idx" ON "partidas"("tenant_id", "conta_id");

-- CreateIndex
CREATE UNIQUE INDEX "fechamentos_periodo_empresa_id_competencia_key" ON "fechamentos_periodo"("empresa_id", "competencia");

-- CreateIndex
CREATE INDEX "documentos_fiscais_empresa_id_data_emissao_idx" ON "documentos_fiscais"("empresa_id", "data_emissao");

-- CreateIndex
CREATE INDEX "documentos_fiscais_empresa_id_situacao_idx" ON "documentos_fiscais"("empresa_id", "situacao");

-- CreateIndex
CREATE UNIQUE INDEX "documentos_fiscais_tenant_id_chave_acesso_key" ON "documentos_fiscais"("tenant_id", "chave_acesso");

-- CreateIndex
CREATE UNIQUE INDEX "itens_documento_fiscal_documento_id_numero_item_key" ON "itens_documento_fiscal"("documento_id", "numero_item");

-- CreateIndex
CREATE INDEX "regras_contabilizacao_empresa_id_prioridade_idx" ON "regras_contabilizacao"("empresa_id", "prioridade");

-- CreateIndex
CREATE UNIQUE INDEX "bancos_codigo_key" ON "bancos"("codigo");

-- CreateIndex
CREATE UNIQUE INDEX "contas_bancarias_empresa_id_banco_id_agencia_numero_conta_key" ON "contas_bancarias"("empresa_id", "banco_id", "agencia", "numero_conta");

-- CreateIndex
CREATE UNIQUE INDEX "extratos_bancarios_hash_unico_key" ON "extratos_bancarios"("hash_unico");

-- CreateIndex
CREATE INDEX "extratos_bancarios_conta_bancaria_id_data_movimento_idx" ON "extratos_bancarios"("conta_bancaria_id", "data_movimento");

-- CreateIndex
CREATE INDEX "extratos_bancarios_conciliado_idx" ON "extratos_bancarios"("conciliado");

-- CreateIndex
CREATE UNIQUE INDEX "apuracoes_empresa_id_competencia_regime_key" ON "apuracoes"("empresa_id", "competencia", "regime");

-- CreateIndex
CREATE INDEX "guias_empresa_id_vencimento_idx" ON "guias"("empresa_id", "vencimento");

-- CreateIndex
CREATE INDEX "guias_status_idx" ON "guias"("status");

-- CreateIndex
CREATE INDEX "tabelas_tributarias_regime_anexo_vigencia_inicio_idx" ON "tabelas_tributarias"("regime", "anexo", "vigencia_inicio");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roles" ADD CONSTRAINT "roles_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permissions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "empresas" ADD CONSTRAINT "empresas_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "socios" ADD CONSTRAINT "socios_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plano_contas" ADD CONSTRAINT "plano_contas_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plano_contas" ADD CONSTRAINT "plano_contas_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas" ADD CONSTRAINT "contas_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas" ADD CONSTRAINT "contas_plano_contas_id_fkey" FOREIGN KEY ("plano_contas_id") REFERENCES "plano_contas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas" ADD CONSTRAINT "contas_conta_pai_id_fkey" FOREIGN KEY ("conta_pai_id") REFERENCES "contas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "centros_custo" ADD CONSTRAINT "centros_custo_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "centros_custo" ADD CONSTRAINT "centros_custo_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historicos_padrao" ADD CONSTRAINT "historicos_padrao_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historicos_padrao" ADD CONSTRAINT "historicos_padrao_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historicos_padrao" ADD CONSTRAINT "historicos_padrao_conta_debito_id_fkey" FOREIGN KEY ("conta_debito_id") REFERENCES "contas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historicos_padrao" ADD CONSTRAINT "historicos_padrao_conta_credito_id_fkey" FOREIGN KEY ("conta_credito_id") REFERENCES "contas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lotes_lancamento" ADD CONSTRAINT "lotes_lancamento_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lotes_lancamento" ADD CONSTRAINT "lotes_lancamento_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lotes_lancamento" ADD CONSTRAINT "lotes_lancamento_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lancamentos" ADD CONSTRAINT "lancamentos_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lancamentos" ADD CONSTRAINT "lancamentos_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lancamentos" ADD CONSTRAINT "lancamentos_lote_id_fkey" FOREIGN KEY ("lote_id") REFERENCES "lotes_lancamento"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lancamentos" ADD CONSTRAINT "lancamentos_estorno_de_id_fkey" FOREIGN KEY ("estorno_de_id") REFERENCES "lancamentos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partidas" ADD CONSTRAINT "partidas_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partidas" ADD CONSTRAINT "partidas_lancamento_id_fkey" FOREIGN KEY ("lancamento_id") REFERENCES "lancamentos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partidas" ADD CONSTRAINT "partidas_conta_id_fkey" FOREIGN KEY ("conta_id") REFERENCES "contas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partidas" ADD CONSTRAINT "partidas_centro_custo_id_fkey" FOREIGN KEY ("centro_custo_id") REFERENCES "centros_custo"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fechamentos_periodo" ADD CONSTRAINT "fechamentos_periodo_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fechamentos_periodo" ADD CONSTRAINT "fechamentos_periodo_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fechamentos_periodo" ADD CONSTRAINT "fechamentos_periodo_fechado_por_fkey" FOREIGN KEY ("fechado_por") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documentos_fiscais" ADD CONSTRAINT "documentos_fiscais_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documentos_fiscais" ADD CONSTRAINT "documentos_fiscais_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documentos_fiscais" ADD CONSTRAINT "documentos_fiscais_lancamento_id_fkey" FOREIGN KEY ("lancamento_id") REFERENCES "lancamentos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itens_documento_fiscal" ADD CONSTRAINT "itens_documento_fiscal_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "itens_documento_fiscal" ADD CONSTRAINT "itens_documento_fiscal_documento_id_fkey" FOREIGN KEY ("documento_id") REFERENCES "documentos_fiscais"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_contabilizacao" ADD CONSTRAINT "regras_contabilizacao_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_contabilizacao" ADD CONSTRAINT "regras_contabilizacao_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_contabilizacao" ADD CONSTRAINT "regras_contabilizacao_conta_debito_id_fkey" FOREIGN KEY ("conta_debito_id") REFERENCES "contas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_contabilizacao" ADD CONSTRAINT "regras_contabilizacao_conta_credito_id_fkey" FOREIGN KEY ("conta_credito_id") REFERENCES "contas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas_bancarias" ADD CONSTRAINT "contas_bancarias_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas_bancarias" ADD CONSTRAINT "contas_bancarias_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas_bancarias" ADD CONSTRAINT "contas_bancarias_banco_id_fkey" FOREIGN KEY ("banco_id") REFERENCES "bancos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contas_bancarias" ADD CONSTRAINT "contas_bancarias_conta_contabil_id_fkey" FOREIGN KEY ("conta_contabil_id") REFERENCES "contas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "extratos_bancarios" ADD CONSTRAINT "extratos_bancarios_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "extratos_bancarios" ADD CONSTRAINT "extratos_bancarios_conta_bancaria_id_fkey" FOREIGN KEY ("conta_bancaria_id") REFERENCES "contas_bancarias"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "extratos_bancarios" ADD CONSTRAINT "extratos_bancarios_lancamento_id_fkey" FOREIGN KEY ("lancamento_id") REFERENCES "lancamentos"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_conciliacao" ADD CONSTRAINT "regras_conciliacao_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_conciliacao" ADD CONSTRAINT "regras_conciliacao_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_conciliacao" ADD CONSTRAINT "regras_conciliacao_conta_debito_id_fkey" FOREIGN KEY ("conta_debito_id") REFERENCES "contas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "regras_conciliacao" ADD CONSTRAINT "regras_conciliacao_conta_credito_id_fkey" FOREIGN KEY ("conta_credito_id") REFERENCES "contas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apuracoes" ADD CONSTRAINT "apuracoes_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apuracoes" ADD CONSTRAINT "apuracoes_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apuracoes_impostos" ADD CONSTRAINT "apuracoes_impostos_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apuracoes_impostos" ADD CONSTRAINT "apuracoes_impostos_apuracao_id_fkey" FOREIGN KEY ("apuracao_id") REFERENCES "apuracoes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guias" ADD CONSTRAINT "guias_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guias" ADD CONSTRAINT "guias_empresa_id_fkey" FOREIGN KEY ("empresa_id") REFERENCES "empresas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guias" ADD CONSTRAINT "guias_apuracao_id_fkey" FOREIGN KEY ("apuracao_id") REFERENCES "apuracoes"("id") ON DELETE SET NULL ON UPDATE CASCADE;
