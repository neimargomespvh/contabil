import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { SociosService } from './socios.service';
import { CreateSocioDto } from './dto/create-socio.dto';
import { UpdateSocioDto } from './dto/update-socio.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('socios')
@ApiBearerAuth()
@Controller('socios')
export class SociosController {
  constructor(private readonly service: SociosService) {}

  @Get('empresa/:empresaId')
  @RequirePermissions(PERMISSIONS.SOCIO_VER)
  @ApiOperation({ summary: 'Lista sócios de uma empresa com resumo de participação' })
  listarPorEmpresa(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
  ) {
    return this.service.listarPorEmpresa(t, empresaId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.SOCIO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.SOCIO_CRIAR)
  @ApiOperation({ summary: 'Cria novo sócio' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateSocioDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.SOCIO_EDITAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSocioDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.SOCIO_EXCLUIR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
