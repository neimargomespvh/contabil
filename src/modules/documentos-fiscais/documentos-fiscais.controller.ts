import {
  Body, Controller, Get, Param, ParseUUIDPipe, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { DocumentosFiscaisService } from './documentos-fiscais.service';
import { ImportarXmlDto } from './dto/importar-xml.dto';
import { FilterDocumentoDto } from './dto/filter-documento.dto';
import { CancelarDocumentoDto } from './dto/cancelar-documento.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('documentos-fiscais')
@ApiBearerAuth()
@Controller('documentos-fiscais')
export class DocumentosFiscaisController {
  constructor(private readonly service: DocumentosFiscaisService) {}

  @Post('importar')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_IMPORTAR)
  @ApiOperation({ summary: 'Importa XML de documento fiscal (NFe/NFCe/CT-e/NFS-e)' })
  importar(@CurrentTenant() t: string, @Body() dto: ImportarXmlDto) {
    return this.service.importarXml(t, dto);
  }

  @Get()
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  @ApiOperation({ summary: 'Lista documentos com filtros e paginação' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterDocumentoDto) {
    return this.service.listar(t, filtros);
  }

  @Get('estatisticas')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  @ApiOperation({ summary: 'Estatísticas de documentos' })
  estatisticas(
    @CurrentTenant() t: string,
    @Query('empresaId') empresaId?: string,
  ) {
    return this.service.estatisticas(t, empresaId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Get(':id/xml')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  @ApiOperation({ summary: 'URL assinada para download do XML (1h)' })
  urlXml(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.gerarUrlXml(t, id);
  }

  @Post(':id/cancelar')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_EXCLUIR)
  @ApiOperation({ summary: 'Marca documento como cancelado' })
  cancelar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelarDocumentoDto,
  ) {
    return this.service.cancelar(t, id, dto.motivo);
  }
}
