import {
  Body, Controller, Get, Param, ParseUUIDPipe, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ConciliacaoService } from './conciliacao.service';
import { ImportarOfxDto } from './dto/importar-ofx.dto';
import { ImportarCsvDto } from './dto/importar-csv.dto';
import { ConciliarManualDto } from './dto/conciliar-manual.dto';
import { FilterExtratoDto } from './dto/filter-extrato.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('conciliacao')
@ApiBearerAuth()
@Controller('conciliacao')
export class ConciliacaoController {
  constructor(private readonly service: ConciliacaoService) {}

  @Post('importar-ofx')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Importa extrato no formato OFX' })
  importarOfx(@CurrentTenant() t: string, @Body() dto: ImportarOfxDto) {
    return this.service.importarOfx(t, dto);
  }

  @Post('importar-csv')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Importa extrato no formato CSV (com mapeamento)' })
  importarCsv(@CurrentTenant() t: string, @Body() dto: ImportarCsvDto) {
    return this.service.importarCsv(t, dto);
  }

  @Get('extratos')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  @ApiOperation({ summary: 'Lista extratos com filtros' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterExtratoDto) {
    return this.service.listar(t, filtros);
  }

  @Post('extratos/:id/conciliar')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Conciliação manual (vincular a lançamento)' })
  conciliarManual(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ConciliarManualDto,
  ) {
    return this.service.conciliarManual(t, id, dto);
  }

  @Post('extratos/:id/desconciliar')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Remove vínculo de conciliação' })
  desconciliar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.desconciliar(t, id);
  }

  @Post('conciliar-lote/:contaBancariaId')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Executa conciliação automática em lote' })
  conciliarLote(
    @CurrentTenant() t: string,
    @Param('contaBancariaId', ParseUUIDPipe) contaBancariaId: string,
  ) {
    return this.service.conciliarLote(t, contaBancariaId);
  }

  @Get('dashboard')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  @ApiOperation({ summary: 'Dashboard de conciliação' })
  dashboard(
    @CurrentTenant() t: string,
    @Query('contaBancariaId') contaBancariaId?: string,
  ) {
    return this.service.dashboard(t, contaBancariaId);
  }
}
