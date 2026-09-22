import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { LancamentosService } from './lancamentos.service';
import { CreateLancamentoDto } from './dto/create-lancamento.dto';
import { EstornoDto } from './dto/estorno.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('lancamentos')
@ApiBearerAuth()
@Controller('lancamentos')
export class LancamentosController {
  constructor(private readonly service: LancamentosService) {}

  @Post()
  @RequirePermissions(PERMISSIONS.LANCAMENTO_CRIAR)
  @ApiOperation({ summary: 'Cria lançamento com partidas dobradas' })
  criar(@CurrentTenant() tenantId: string, @Body() dto: CreateLancamentoDto) {
    return this.service.criar(tenantId, dto);
  }

  @Get()
  @RequirePermissions(PERMISSIONS.LANCAMENTO_VER)
  @ApiOperation({ summary: 'Lista lançamentos com paginação' })
  listar(
    @CurrentTenant() tenantId: string,
    @Query('empresaId') empresaId: string,
    @Query('competencia') competencia?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.service.listarPaginado(
      tenantId,
      empresaId,
      competencia,
      page ? Number(page) : 1,
      limit ? Number(limit) : 30,
    );
  }

 
  @Get(':id')
  @RequirePermissions(PERMISSIONS.LANCAMENTO_VER)
  buscar(
    @CurrentTenant() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.buscarPorId(tenantId, id);
  }

  @Post(':id/estornar')
  @RequirePermissions(PERMISSIONS.LANCAMENTO_ESTORNAR)
  @ApiOperation({ summary: 'Estorna lançamento criando partida inversa' })
  estornar(
    @CurrentTenant() tenantId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: EstornoDto,
  ) {
    return this.service.estornar(tenantId, id, dto.motivo);
  }
}