export interface ContaPadrao {
  codigo: string;
  nome: string;
  natureza: 'ATIVO' | 'PASSIVO' | 'PATRIMONIO_LIQUIDO' | 'RECEITA' | 'DESPESA' | 'CUSTO';
  tipo: 'SINTETICA' | 'ANALITICA';
  dreLinha?: string;
}

/**
 * Plano de contas padrão brasileiro (versão resumida).
 * Baseado na estrutura da Receita Federal, adaptado para uso em escritórios.
 */
export const PLANO_PADRAO: ContaPadrao[] = [
  // ============ ATIVO ============
  { codigo: '1', nome: 'ATIVO', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1', nome: 'ATIVO CIRCULANTE', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.1', nome: 'DISPONIBILIDADES', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.1.01', nome: 'Caixa', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.1.02', nome: 'Bancos Conta Movimento', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.1.03', nome: 'Aplicações Financeiras', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.1.2', nome: 'CLIENTES', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.2.01', nome: 'Clientes Nacionais', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.2.02', nome: 'Clientes Estrangeiros', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.2.03', nome: '(-) Duplicatas Descontadas', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.1.3', nome: 'ESTOQUES', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.3.01', nome: 'Mercadorias para Revenda', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.3.02', nome: 'Matéria-Prima', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.3.03', nome: 'Produtos Acabados', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.1.4', nome: 'IMPOSTOS A RECUPERAR', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.4.01', nome: 'ICMS a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.02', nome: 'PIS a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.03', nome: 'COFINS a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.04', nome: 'IRPJ a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.05', nome: 'CSLL a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.2', nome: 'ATIVO NÃO CIRCULANTE', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.2.1', nome: 'REALIZÁVEL A LONGO PRAZO', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.2.1.01', nome: 'Aplicações Financeiras LP', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.1.02', nome: 'Depósitos Judiciais', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.2.2', nome: 'IMOBILIZADO', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.2.2.01', nome: 'Imóveis', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.02', nome: 'Veículos', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.03', nome: 'Móveis e Utensílios', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.04', nome: 'Máquinas e Equipamentos', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.05', nome: '(-) Depreciação Acumulada', natureza: 'ATIVO', tipo: 'ANALITICA' },

  // ============ PASSIVO ============
  { codigo: '2', nome: 'PASSIVO', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1', nome: 'PASSIVO CIRCULANTE', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.1', nome: 'FORNECEDORES', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.1.01', nome: 'Fornecedores Nacionais', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.1.02', nome: 'Fornecedores Estrangeiros', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.1.2', nome: 'OBRIGAÇÕES TRABALHISTAS', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.2.01', nome: 'Salários a Pagar', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.2.02', nome: 'FGTS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.2.03', nome: 'INSS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.2.04', nome: 'IRRF a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.1.3', nome: 'OBRIGAÇÕES TRIBUTÁRIAS', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.3.01', nome: 'ICMS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.02', nome: 'PIS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.03', nome: 'COFINS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.04', nome: 'IRPJ a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.05', nome: 'CSLL a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.06', nome: 'ISS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.07', nome: 'DAS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.1.4', nome: 'EMPRÉSTIMOS E FINANCIAMENTOS', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.4.01', nome: 'Empréstimos Bancários CP', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.2', nome: 'PASSIVO NÃO CIRCULANTE', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.2.1', nome: 'EMPRÉSTIMOS E FINANCIAMENTOS LP', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.2.1.01', nome: 'Financiamentos LP', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  // ============ PATRIMÔNIO LÍQUIDO ============
  { codigo: '2.3', nome: 'PATRIMÔNIO LÍQUIDO', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'SINTETICA' },
  { codigo: '2.3.1', nome: 'CAPITAL SOCIAL', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
  { codigo: '2.3.2', nome: 'LUCROS ACUMULADOS', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
  { codigo: '2.3.3', nome: 'PREJUÍZOS ACUMULADOS', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
  { codigo: '2.3.4', nome: 'RESERVAS', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },

  // ============ RECEITAS ============
  { codigo: '3', nome: 'RECEITAS', natureza: 'RECEITA', tipo: 'SINTETICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1', nome: 'RECEITA BRUTA', natureza: 'RECEITA', tipo: 'SINTETICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1.1', nome: 'Vendas de Mercadorias', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1.2', nome: 'Prestação de Serviços', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1.3', nome: 'Receitas Financeiras', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'RECEITA_FINANCEIRA' },
  { codigo: '3.1.4', nome: 'Outras Receitas', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'OUTRAS_RECEITAS' },

  { codigo: '3.2', nome: 'DEDUÇÕES DA RECEITA', natureza: 'RECEITA', tipo: 'SINTETICA', dreLinha: 'DEDUCOES' },
  { codigo: '3.2.1', nome: '(-) Impostos sobre Vendas', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'DEDUCOES' },
  { codigo: '3.2.2', nome: '(-) Devoluções de Vendas', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'DEDUCOES' },

  // ============ CUSTOS ============
  { codigo: '4', nome: 'CUSTOS', natureza: 'CUSTO', tipo: 'SINTETICA', dreLinha: 'CUSTO_PRODUTOS' },
  { codigo: '4.1', nome: 'CUSTO DAS MERCADORIAS VENDIDAS', natureza: 'CUSTO', tipo: 'ANALITICA', dreLinha: 'CUSTO_PRODUTOS' },
  { codigo: '4.2', nome: 'CUSTO DOS SERVIÇOS PRESTADOS', natureza: 'CUSTO', tipo: 'ANALITICA', dreLinha: 'CUSTO_SERVICOS' },

  // ============ DESPESAS ============
  { codigo: '5', nome: 'DESPESAS', natureza: 'DESPESA', tipo: 'SINTETICA' },
  { codigo: '5.1', nome: 'DESPESAS OPERACIONAIS', natureza: 'DESPESA', tipo: 'SINTETICA' },
  { codigo: '5.1.1', nome: 'Despesas com Pessoal', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_PESSOAL' },
  { codigo: '5.1.2', nome: 'Despesas Administrativas', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_ADMIN' },
  { codigo: '5.1.3', nome: 'Despesas Comerciais', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_COMERCIAIS' },
  { codigo: '5.1.4', nome: 'Despesas Tributárias', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_TRIBUTARIAS' },
  { codigo: '5.1.5', nome: 'Despesas Financeiras', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_FINANCEIRAS' },

  { codigo: '5.2', nome: 'OUTRAS DESPESAS', natureza: 'DESPESA', tipo: 'SINTETICA' },
  { codigo: '5.2.1', nome: 'Perdas Diversas', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'OUTRAS_DESPESAS' },

  // ============ APURAÇÃO ============
  { codigo: '6', nome: 'APURAÇÃO DO RESULTADO', natureza: 'RECEITA', tipo: 'SINTETICA' },
  { codigo: '6.1', nome: 'Resultado do Exercício', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
];
