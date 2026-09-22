import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CentrosCustoService } from './centros-custo.service';
import { CreateCentroCustoDto } from './dto/create-centro.dto';
import { UpdateCentroCustoDto } from './dto/update-centro.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('centros-custo')
@ApiBearerAuth()
@Controller('centros-custo')
export class CentrosCustoController {
  constructor(private readonly service: CentrosCustoService) {}

  @Get('empresa/:empresaId')
  @RequirePermissions(PERMISSIONS.PLANO_VER)
  @ApiOperation({ summary: 'Lista centros de custo da empresa' })
  listar(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
  ) {
    return this.service.listar(t, empresaId);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  criar(@CurrentTenant() t: string, @Body() dto: CreateCentroCustoDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCentroCustoDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
