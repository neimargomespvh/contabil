import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { EmpresasService } from './empresas.service';
import { CreateEmpresaDto } from './dto/create-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { FilterEmpresaDto } from './dto/filter-empresa.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('empresas')
@ApiBearerAuth()
@Controller('empresas')
export class EmpresasController {
  constructor(private readonly service: EmpresasService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.EMPRESA_VER)
  @ApiOperation({ summary: 'Lista empresas com filtros e paginação' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterEmpresaDto) {
    return this.service.listar(t, filtros);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.EMPRESA_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.EMPRESA_CRIAR)
  @ApiOperation({ summary: 'Cria nova empresa' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateEmpresaDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.EMPRESA_EDITAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateEmpresaDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.EMPRESA_EXCLUIR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
