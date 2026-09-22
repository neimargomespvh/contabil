import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ContasBancariasService } from './contas-bancarias.service';
import { CreateContaBancariaDto } from './dto/create-conta-bancaria.dto';
import { UpdateContaBancariaDto } from './dto/update-conta-bancaria.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('contas-bancarias')
@ApiBearerAuth()
@Controller('contas-bancarias')
export class ContasBancariasController {
  constructor(private readonly service: ContasBancariasService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  @ApiOperation({ summary: 'Lista contas bancárias' })
  listar(
    @CurrentTenant() t: string,
    @Query('empresaId') empresaId?: string,
  ) {
    return this.service.listar(t, empresaId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  criar(@CurrentTenant() t: string, @Body() dto: CreateContaBancariaDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateContaBancariaDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
