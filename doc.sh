docker exec -it contabil-postgres psql -U postgres -d contabil <<EOF
INSERT INTO regras_contabilizacao (
  id, tenant_id, empresa_id, nome, prioridade, condicao,
  conta_debito_id, conta_credito_id, historico_template, status, created_at
) VALUES (
  gen_random_uuid(),
  (SELECT tenant_id FROM empresas WHERE id = '$EMPRESA_ID'),
  '$EMPRESA_ID',
  'Compra de mercadoria',
  1,
  '{"tipo":"NFE","cfop":["5102","6102"]}'::jsonb,
  '$CONTA_ESTOQUE',
  '$CONTA_FORNECEDOR',
  'NF {numero}/{serie} - {emitente}',
  'ATIVO',
  NOW()
);
EOF