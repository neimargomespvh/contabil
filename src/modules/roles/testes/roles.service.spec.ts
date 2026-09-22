import { Test } from '@nestjs/testing';
import { RolesService } from '../roles.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('RolesService', () => {
  let service: RolesService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      role: { findFirst: jest.fn(), create: jest.fn(), delete: jest.fn(), findMany: jest.fn() },
      rolePermission: { createMany: jest.fn(), deleteMany: jest.fn() },
      permission: { findMany: jest.fn(), findFirst: jest.fn() },
      $transaction: jest.fn((fn) => fn(prisma)),
    };
    const m = await Test.createTestingModule({
      providers: [RolesService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = m.get(RolesService);
  });

  it('rejeita nome duplicado', async () => {
    prisma.role.findFirst.mockResolvedValue({ id: 'r1', nome: 'admin' });
    await expect(
      service.criar('t1', { nome: 'admin' }),
    ).rejects.toThrow();
  });
});
