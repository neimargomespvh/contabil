import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RegrasContabilizacaoService } from './regras-contabilizacao.service';
import { CreateRegraDto } from './dto/create-regra.dto';
import { UpdateRegraDto } from './dto/update-regra.dto';
import { FilterRegraDto } from './dto/filter-regra.dto';
import { ReordenarRegrasDto } from './dto/reordenar.dto';
import { SimularRegraDto } from './dto/simular.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';

@ApiTags('regras-contabilizacao')
@ApiBearerAuth()
@Controller('regras-contabilizacao')
export class RegrasContabilizacaoController {
  constructor(private readonly service: RegrasContabilizacaoService) {}

  @Post()
  @RequirePermissions('regra.criar')
  @ApiOperation({ summary: 'Cria uma regra de contabilização' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateRegraDto) {
    return this.service.criar(t, dto);
  }

  @Get()
  @RequirePermissions('regra.ver')
  @ApiOperation({ summary: 'Lista regras com filtros e paginação' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterRegraDto) {
    return this.service.listar(t, filtros);
  }

  @Post('reordenar')
  @RequirePermissions('regra.editar')
  @ApiOperation({ summary: 'Reordena prioridades em lote' })
  reordenar(@CurrentTenant() t: string, @Body() dto: ReordenarRegrasDto) {
    return this.service.reordenar(t, dto);
  }

  @Post('simular')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions('regra.ver')
  @ApiOperation({ summary: 'Simula qual regra casaria com um XML' })
  simular(@CurrentTenant() t: string, @Body() dto: SimularRegraDto) {
    return this.service.simular(t, dto.empresaId, dto.xml);
  }

  @Get(':id')
  @RequirePermissions('regra.ver')
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Patch(':id')
  @RequirePermissions('regra.editar')
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRegraDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Patch(':id/inativar')
  @RequirePermissions('regra.editar')
  @ApiOperation({ summary: 'Inativa a regra (soft)' })
  inativar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.inativar(t, id);
  }

  @Patch(':id/reativar')
  @RequirePermissions('regra.editar')
  @ApiOperation({ summary: 'Reativa a regra' })
  reativar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.reativar(t, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  @RequirePermissions('regra.excluir')
  @ApiOperation({ summary: 'Exclui permanentemente' })
  excluir(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.excluir(t, id);
  }
}
