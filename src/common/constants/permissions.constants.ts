export const PERMISSIONS = {
  // Empresas
  EMPRESA_CRIAR: 'empresa.criar',
  EMPRESA_EDITAR: 'empresa.editar',
  EMPRESA_EXCLUIR: 'empresa.excluir',
  EMPRESA_VER: 'empresa.ver',

  // Sócios
  SOCIO_CRIAR: 'socio.criar',
  SOCIO_EDITAR: 'socio.editar',
  SOCIO_EXCLUIR: 'socio.excluir',
  SOCIO_VER: 'socio.ver',

  // Plano de contas
  PLANO_CRIAR: 'plano.criar',
  PLANO_EDITAR: 'plano.editar',
  PLANO_VER: 'plano.ver',

  // Lançamentos
  LANCAMENTO_CRIAR: 'lancamento.criar',
  LANCAMENTO_EDITAR: 'lancamento.editar',
  LANCAMENTO_ESTORNAR: 'lancamento.estornar',
  LANCAMENTO_VER: 'lancamento.ver',

  // Documentos fiscais
  DOCUMENTO_IMPORTAR: 'documento.importar',
  DOCUMENTO_EXCLUIR: 'documento.excluir',
  DOCUMENTO_VER: 'documento.ver',

  // Conciliação
  CONCILIACAO_EXECUTAR: 'conciliacao.executar',
  CONCILIACAO_VER: 'conciliacao.ver',

  // Apuração
  APURACAO_CALCULAR: 'apuracao.calcular',
  APURACAO_VER: 'apuracao.ver',

  // Relatórios
  RELATORIO_GERAR: 'relatorio.gerar',
  RELATORIO_VER: 'relatorio.ver',

  // Administração
  USUARIO_GERENCIAR: 'usuario.gerenciar',
  USUARIO_VER: 'usuario.ver',
  ROLE_GERENCIAR: 'role.gerenciar',
  ROLE_VER: 'role.ver',
  AUDITORIA_VER: 'auditoria.ver',
} as const;

export type PermissionCode = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

export const TODAS_PERMISSOES: string[] = Object.values(PERMISSIONS);

// Descrições legíveis para exibir no frontend
export const PERMISSOES_DESCRICOES: Record<string, string> = {
  [PERMISSIONS.EMPRESA_CRIAR]: 'Criar empresas',
  [PERMISSIONS.EMPRESA_EDITAR]: 'Editar empresas',
  [PERMISSIONS.EMPRESA_EXCLUIR]: 'Excluir empresas',
  [PERMISSIONS.EMPRESA_VER]: 'Visualizar empresas',
  [PERMISSIONS.SOCIO_CRIAR]: 'Criar sócios',
  [PERMISSIONS.SOCIO_EDITAR]: 'Editar sócios',
  [PERMISSIONS.SOCIO_EXCLUIR]: 'Excluir sócios',
  [PERMISSIONS.SOCIO_VER]: 'Visualizar sócios',
  [PERMISSIONS.PLANO_CRIAR]: 'Criar planos de contas',
  [PERMISSIONS.PLANO_EDITAR]: 'Editar planos de contas',
  [PERMISSIONS.PLANO_VER]: 'Visualizar planos de contas',
  [PERMISSIONS.LANCAMENTO_CRIAR]: 'Criar lançamentos',
  [PERMISSIONS.LANCAMENTO_EDITAR]: 'Editar lançamentos',
  [PERMISSIONS.LANCAMENTO_ESTORNAR]: 'Estornar lançamentos',
  [PERMISSIONS.LANCAMENTO_VER]: 'Visualizar lançamentos',
  [PERMISSIONS.DOCUMENTO_IMPORTAR]: 'Importar documentos fiscais',
  [PERMISSIONS.DOCUMENTO_EXCLUIR]: 'Excluir documentos fiscais',
  [PERMISSIONS.DOCUMENTO_VER]: 'Visualizar documentos fiscais',
  [PERMISSIONS.CONCILIACAO_EXECUTAR]: 'Executar conciliação bancária',
  [PERMISSIONS.CONCILIACAO_VER]: 'Visualizar conciliação',
  [PERMISSIONS.APURACAO_CALCULAR]: 'Calcular apurações tributárias',
  [PERMISSIONS.APURACAO_VER]: 'Visualizar apurações',
  [PERMISSIONS.RELATORIO_GERAR]: 'Gerar relatórios',
  [PERMISSIONS.RELATORIO_VER]: 'Visualizar relatórios',
  [PERMISSIONS.USUARIO_GERENCIAR]: 'Gerenciar usuários',
  [PERMISSIONS.USUARIO_VER]: 'Visualizar usuários',
  [PERMISSIONS.ROLE_GERENCIAR]: 'Gerenciar perfis e permissões',
  [PERMISSIONS.ROLE_VER]: 'Visualizar perfis',
  [PERMISSIONS.AUDITORIA_VER]: 'Visualizar auditoria',
};

// Perfis padrão criados para cada novo tenant
export interface RolePadrao {
  nome: string;
  descricao: string;
  permissoes: string[];
}

export const ROLES_PADRAO: RolePadrao[] = [
  {
    nome: 'admin',
    descricao: 'Administrador — acesso total ao sistema',
    permissoes: TODAS_PERMISSOES,
  },
  {
    nome: 'contador',
    descricao: 'Contador — acesso contábil, fiscal e relatórios',
    permissoes: [
      PERMISSIONS.EMPRESA_CRIAR,
      PERMISSIONS.EMPRESA_EDITAR,
      PERMISSIONS.EMPRESA_VER,
      PERMISSIONS.SOCIO_CRIAR,
      PERMISSIONS.SOCIO_EDITAR,
      PERMISSIONS.SOCIO_VER,
      PERMISSIONS.PLANO_CRIAR,
      PERMISSIONS.PLANO_EDITAR,
      PERMISSIONS.PLANO_VER,
      PERMISSIONS.LANCAMENTO_CRIAR,
      PERMISSIONS.LANCAMENTO_EDITAR,
      PERMISSIONS.LANCAMENTO_ESTORNAR,
      PERMISSIONS.LANCAMENTO_VER,
      PERMISSIONS.DOCUMENTO_IMPORTAR,
      PERMISSIONS.DOCUMENTO_VER,
      PERMISSIONS.CONCILIACAO_EXECUTAR,
      PERMISSIONS.CONCILIACAO_VER,
      PERMISSIONS.APURACAO_CALCULAR,
      PERMISSIONS.APURACAO_VER,
      PERMISSIONS.RELATORIO_GERAR,
      PERMISSIONS.RELATORIO_VER,
      PERMISSIONS.USUARIO_VER,
      PERMISSIONS.ROLE_VER,
    ],
  },
  {
    nome: 'auxiliar',
    descricao: 'Auxiliar contábil — lançamentos e visualização',
    permissoes: [
      PERMISSIONS.EMPRESA_VER,
      PERMISSIONS.SOCIO_VER,
      PERMISSIONS.PLANO_VER,
      PERMISSIONS.LANCAMENTO_CRIAR,
      PERMISSIONS.LANCAMENTO_EDITAR,
      PERMISSIONS.LANCAMENTO_VER,
      PERMISSIONS.DOCUMENTO_IMPORTAR,
      PERMISSIONS.DOCUMENTO_VER,
      PERMISSIONS.CONCILIACAO_EXECUTAR,
      PERMISSIONS.CONCILIACAO_VER,
      PERMISSIONS.APURACAO_VER,
      PERMISSIONS.RELATORIO_VER,
    ],
  },
  {
    nome: 'leitura',
    descricao: 'Somente leitura — sem permissão de escrita',
    permissoes: [
      PERMISSIONS.EMPRESA_VER,
      PERMISSIONS.SOCIO_VER,
      PERMISSIONS.PLANO_VER,
      PERMISSIONS.LANCAMENTO_VER,
      PERMISSIONS.DOCUMENTO_VER,
      PERMISSIONS.CONCILIACAO_VER,
      PERMISSIONS.APURACAO_VER,
      PERMISSIONS.RELATORIO_VER,
    ],
  },
];
