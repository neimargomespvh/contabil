import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RelatoriosService } from './relatorios.service';
import { FilterRelatorioDto, ComparativoDto } from './dto/filter-relatorio.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('relatorios')
@ApiBearerAuth()
@Controller('relatorios')
export class RelatoriosController {
  constructor(private readonly service: RelatoriosService) {}

  @Get('balancete')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Balancete por período (JSON/PDF/EXCEL)' })
  balancete(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.balancete(t, filtros);
  }

  @Get('balanco')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Balanço patrimonial' })
  balanco(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.balanco(t, filtros);
  }

  @Get('dre')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'DRE — Demonstrativo de Resultado' })
  dre(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.dre(t, filtros);
  }

  @Get('dre/comparativo')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'DRE comparativo entre períodos' })
  comparativo(@CurrentTenant() t: string, @Query() dto: ComparativoDto) {
    return this.service.comparativoDre(t, dto);
  }

  @Get('razao/:contaId')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Razão analítico de uma conta' })
  razao(
    @CurrentTenant() t: string,
    @Param('contaId', ParseUUIDPipe) contaId: string,
    @Query() filtros: FilterRelatorioDto,
  ) {
    return this.service.razao(t, contaId, filtros);
  }

  @Get('livro-diario')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Livro diário por período' })
  livroDiario(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.livroDiario(t, filtros);
  }

  @Get('fluxo-caixa')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Fluxo de caixa' })
  fluxoCaixa(
    @CurrentTenant() t: string,
    @Query() filtros: FilterRelatorioDto,
    @Query('contaBancariaId') contaBancariaId?: string,
  ) {
    return this.service.fluxoCaixa(t, filtros, contaBancariaId);
  }
}
