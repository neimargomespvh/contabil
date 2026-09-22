import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PlanoContasService } from './plano-contas.service';
import { CreatePlanoDto } from './dto/create-plano.dto';
import { CreateContaDto } from './dto/create-conta.dto';
import { UpdateContaDto } from './dto/update-conta.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('plano-contas')
@ApiBearerAuth()
@Controller('empresas/:empresaId/plano-contas')
export class PlanoContasController {
  constructor(private readonly service: PlanoContasService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.PLANO_VER)
  @ApiOperation({ summary: 'Lista planos de conta da empresa' })
  listarPlanos(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
  ) {
    return this.service.listarPlanos(t, empresaId);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  @ApiOperation({ summary: 'Cria plano de contas vazio' })
  criarPlano(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
    @Body() dto: CreatePlanoDto,
  ) {
    return this.service.criarPlano(t, empresaId, dto);
  }

  @Post('padrao')
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  @ApiOperation({ summary: 'Cria plano com contas padrão brasileiras' })
  criarPlanoPadrao(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
    @Query('nome') nome?: string,
  ) {
    return this.service.criarPlanoPadrao(t, empresaId, nome);
  }
}

@ApiTags('plano-contas')
@ApiBearerAuth()
@Controller('planos')
export class ContasController {
  constructor(private readonly service: PlanoContasService) {}

  @Get(':planoId/contas')
  @RequirePermissions(PERMISSIONS.PLANO_VER)
  @ApiOperation({ summary: 'Lista contas em árvore hierárquica' })
  listarContas(
    @CurrentTenant() t: string,
    @Param('planoId', ParseUUIDPipe) planoId: string,
  ) {
    return this.service.listarContas(t, planoId);
  }

  @Post(':planoId/contas')
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  @ApiOperation({ summary: 'Cria nova conta dentro do plano' })
  criarConta(
    @CurrentTenant() t: string,
    @Param('planoId', ParseUUIDPipe) planoId: string,
    @Body() dto: CreateContaDto,
  ) {
    return this.service.criarConta(t, planoId, dto);
  }

  @Patch('contas/:id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  atualizarConta(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateContaDto,
  ) {
    return this.service.atualizarConta(t, id, dto);
  }

  @Delete('contas/:id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  removerConta(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.removerConta(t, id);
  }
}
