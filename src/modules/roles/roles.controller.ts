import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RolesService } from './roles.service';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { AssignPermissionsDto } from './dto/assign-permissions.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('roles')
@ApiBearerAuth()
@Controller('roles')
export class RolesController {
  constructor(private readonly service: RolesService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.ROLE_VER)
  @ApiOperation({ summary: 'Lista perfis do tenant' })
  listar(@CurrentTenant() tenantId: string) {
    return this.service.listar(tenantId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.ROLE_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  @ApiOperation({ summary: 'Cria novo perfil' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateRoleDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRoleDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }

  @Put(':id/permissoes')
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  @ApiOperation({ summary: 'Substitui as permissões do perfil' })
  atribuir(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignPermissionsDto,
  ) {
    return this.service.atribuirPermissoes(t, id, dto.permissoes);
  }
}
