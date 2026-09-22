import {
  Body, Controller, Get, Param, ParseUUIDPipe, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ApuracoesService } from './apuracoes.service';
import { CalcularApuracaoDto } from './dto/calcular-apuracao.dto';
import { FilterApuracaoDto } from './dto/filter-apuracao.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('apuracoes')
@ApiBearerAuth()
@Controller('apuracoes')
export class ApuracoesController {
  constructor(private readonly service: ApuracoesService) {}

  @Post('calcular')
  @RequirePermissions(PERMISSIONS.APURACAO_CALCULAR)
  @ApiOperation({ summary: 'Calcula apuração tributária' })
  calcular(@CurrentTenant() t: string, @Body() dto: CalcularApuracaoDto) {
    return this.service.calcular(t, dto);
  }

  @Get()
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  @ApiOperation({ summary: 'Lista apurações' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterApuracaoDto) {
    return this.service.listar(t, filtros);
  }

  @Get('guias')
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  @ApiOperation({ summary: 'Lista guias geradas' })
  listarGuias(
    @CurrentTenant() t: string,
    @Query('empresaId') empresaId?: string,
  ) {
    return this.service.listarGuias(t, empresaId);
  }

  @Get('guias/:id/url')
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  @ApiOperation({ summary: 'URL assinada do PDF da guia' })
  urlGuia(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.urlGuia(t, id);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post(':id/gerar-guia')
  @RequirePermissions(PERMISSIONS.APURACAO_CALCULAR)
  @ApiOperation({ summary: 'Gera guia em PDF (DAS/DARF)' })
  gerarGuia(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.gerarGuia(t, id);
  }
}
