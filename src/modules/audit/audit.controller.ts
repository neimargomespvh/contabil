import { Controller, Get, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from './audit.service';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';

@ApiTags('audit')
@ApiBearerAuth()
@Controller('audit')
export class AuditController {
  constructor(private readonly service: AuditService) {}

  @Get('entidade/:entidade/:id')
  @RequirePermissions('auditoria.ver')
  listar(@CurrentTenant() t: string, @Param('entidade') e: string, @Param('id') id: string) {
    return this.service.listarPorEntidade(t, e, id);
  }
}
