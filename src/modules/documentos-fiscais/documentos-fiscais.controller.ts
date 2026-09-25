import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UploadedFile,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
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
  @ApiOperation({ summary: 'Importa XML via JSON (string do XML)' })
  importar(@CurrentTenant() t: string, @Body() dto: ImportarXmlDto) {
    return this.service.importarXml(t, dto);
  }

  @Post('upload')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_IMPORTAR)
  @ApiOperation({ summary: 'Upload de 1 arquivo XML' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        empresaId: { type: 'string', format: 'uuid' },
        file: { type: 'string', format: 'binary' },
      },
      required: ['empresaId', 'file'],
    },
  })
  @UseInterceptors(FileInterceptor('file'))
  async upload(
    @CurrentTenant() t: string,
    @Body('empresaId') empresaId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('Arquivo não enviado');
    if (!empresaId) throw new BadRequestException('empresaId obrigatório');

    const xml = file.buffer.toString('utf-8');
    return this.service.importarXml(t, { empresaId, xml } as ImportarXmlDto);
  }

  @Post('upload-lote')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_IMPORTAR)
  @ApiOperation({ summary: 'Upload de múltiplos XMLs (até 100)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        empresaId: { type: 'string', format: 'uuid' },
        files: {
          type: 'array',
          items: { type: 'string', format: 'binary' },
        },
      },
      required: ['empresaId', 'files'],
    },
  })
  @UseInterceptors(FilesInterceptor('files', 100))
  async uploadLote(
    @CurrentTenant() t: string,
    @Body('empresaId') empresaId: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    if (!files || files.length === 0)
      throw new BadRequestException('Nenhum arquivo enviado');
    if (!empresaId) throw new BadRequestException('empresaId obrigatório');

    const xmls = files.map((f) => f.buffer.toString('utf-8'));
    return this.service.importarLote(t, empresaId, xmls);
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