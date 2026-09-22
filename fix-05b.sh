#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

# ============================================================
# 1. CRIAR AS PASTAS DE TESTES PRIMEIRO
# ============================================================
mkdir -p src/common/utils/testes
mkdir -p src/modules/empresas/testes
mkdir -p src/modules/socios/testes

# ============================================================
# 2. TESTE DE CNPJ/CPF
# ============================================================
cat > src/common/utils/testes/cnpj-cpf.spec.ts <<'TEST_EOF'
import { validarCnpj, limparCnpj, formatarCnpj } from '../cnpj.util';
import { validarCpf, limparCpf, formatarCpf } from '../cpf.util';

describe('Validação de CNPJ', () => {
  it('aceita CNPJ válido (sem máscara)', () => {
    expect(validarCnpj('11222333000181')).toBe(true);
  });

  it('aceita CNPJ válido (com máscara)', () => {
    expect(validarCnpj('11.222.333/0001-81')).toBe(true);
  });

  it('rejeita CNPJ com dígito verificador errado', () => {
    expect(validarCnpj('11222333000182')).toBe(false);
  });

  it('rejeita CNPJ com todos os dígitos iguais', () => {
    expect(validarCnpj('11111111111111')).toBe(false);
  });

  it('rejeita CNPJ com tamanho inválido', () => {
    expect(validarCnpj('123')).toBe(false);
  });

  it('limparCnpj remove máscara', () => {
    expect(limparCnpj('11.222.333/0001-81')).toBe('11222333000181');
  });

  it('formatarCnpj adiciona máscara', () => {
    expect(formatarCnpj('11222333000181')).toBe('11.222.333/0001-81');
  });
});

describe('Validação de CPF', () => {
  it('aceita CPF válido (sem máscara)', () => {
    expect(validarCpf('12345678909')).toBe(true);
  });

  it('aceita CPF válido (com máscara)', () => {
    expect(validarCpf('123.456.789-09')).toBe(true);
  });

  it('rejeita CPF com dígito verificador errado', () => {
    expect(validarCpf('12345678908')).toBe(false);
  });

  it('rejeita CPF com todos os dígitos iguais', () => {
    expect(validarCpf('11111111111')).toBe(false);
  });

  it('rejeita CPF com tamanho inválido', () => {
    expect(validarCpf('123')).toBe(false);
  });

  it('limparCpf remove máscara', () => {
    expect(limparCpf('123.456.789-09')).toBe('12345678909');
  });

  it('formatarCpf adiciona máscara', () => {
    expect(formatarCpf('12345678909')).toBe('123.456.789-09');
  });
});
TEST_EOF

# ============================================================
# 3. TESTE DE SÓCIOS
# ============================================================
cat > src/modules/socios/testes/socios.service.spec.ts <<'TEST_EOF'
import { Test } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { SociosService } from '../socios.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('SociosService', () => {
  let service: SociosService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      empresa: { findFirst: jest.fn().mockResolvedValue({ id: 'e1' }) },
      socio: {
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const module = await Test.createTestingModule({
      providers: [SociosService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(SociosService);
  });

  it('cria sócio com CPF válido e participação OK', async () => {
    prisma.socio.create.mockResolvedValue({ id: 's1' });
    const r = await service.criar('t1', {
      empresaId: 'e1',
      nome: 'João Silva',
      cpf: '12345678909',
      participacao: 50,
    });
    expect(r.id).toBe('s1');
  });

  it('rejeita CPF inválido', async () => {
    await expect(
      service.criar('t1', {
        empresaId: 'e1',
        nome: 'João',
        cpf: '11111111111',
        participacao: 50,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita quando soma de participação ultrapassa 100%', async () => {
    prisma.socio.findMany.mockResolvedValue([{ participacao: 80 }]);
    await expect(
      service.criar('t1', {
        empresaId: 'e1',
        nome: 'João',
        cpf: '12345678909',
        participacao: 30,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita sócio de empresa inexistente', async () => {
    prisma.empresa.findFirst.mockResolvedValue(null);
    await expect(
      service.criar('t1', {
        empresaId: 'inexistente',
        nome: 'João',
        cpf: '12345678909',
        participacao: 50,
      }),
    ).rejects.toThrow(NotFoundException);
  });
});
TEST_EOF

# ============================================================
# 4. TESTE DE EMPRESAS
# ============================================================
cat > src/modules/empresas/testes/empresas.service.spec.ts <<'TEST_EOF'
import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { EmpresasService } from '../empresas.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { RegimeTributarioEnum } from '../dto/create-empresa.dto';

describe('EmpresasService', () => {
  let service: EmpresasService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      empresa: {
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const module = await Test.createTestingModule({
      providers: [EmpresasService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(EmpresasService);
  });

  it('cria empresa com CNPJ válido', async () => {
    prisma.empresa.create.mockResolvedValue({ id: 'e1' });
    const r = await service.criar('t1', {
      razaoSocial: 'Empresa Teste LTDA',
      cnpj: '11222333000181',
      regimeTributario: RegimeTributarioEnum.SIMPLES,
    });
    expect(r.id).toBe('e1');
  });

  it('rejeita CNPJ inválido', async () => {
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000182',
        regimeTributario: RegimeTributarioEnum.SIMPLES,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita CNPJ duplicado', async () => {
    prisma.empresa.findFirst.mockResolvedValue({ id: 'existente' });
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000181',
        regimeTributario: RegimeTributarioEnum.SIMPLES,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('rejeita anexo Simples em regime não-SIMPLES', async () => {
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000181',
        regimeTributario: RegimeTributarioEnum.PRESUMIDO,
        anexoSimples: 'I' as any,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita CPF de responsável inválido', async () => {
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000181',
        regimeTributario: RegimeTributarioEnum.SIMPLES,
        responsavelCpf: '11111111111',
      }),
    ).rejects.toThrow(BadRequestException);
  });
});
TEST_EOF

# ============================================================
# 5. ATUALIZAR APP.MODULE
# ============================================================
python3 <<'PYEOF'
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'EmpresasModule' not in content:
    content = content.replace(
        "import { PermissionsModule } from './modules/permissions/permissions.module';",
        "import { PermissionsModule } from './modules/permissions/permissions.module';\n"
        "import { EmpresasModule } from './modules/empresas/empresas.module';\n"
        "import { SociosModule } from './modules/socios/socios.module';"
    )
    content = content.replace(
        "    PermissionsModule,\n    HealthModule,",
        "    PermissionsModule,\n    EmpresasModule,\n    SociosModule,\n    HealthModule,"
    )
    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado com EmpresasModule e SociosModule")
else:
    print("ℹ️  AppModule já está atualizado")
PYEOF

echo ""
echo "✅ Correção F3 aplicada!"
echo ""
echo "Rode agora:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"