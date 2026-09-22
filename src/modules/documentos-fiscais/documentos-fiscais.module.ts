import { Module } from '@nestjs/common';
import { DocumentosFiscaisController } from './documentos-fiscais.controller';
import { DocumentosFiscaisService } from './documentos-fiscais.service';
import { ImportacaoService } from './services/importacao.service';
import { ContabilizacaoService } from './services/contabilizacao.service';

@Module({
  controllers: [DocumentosFiscaisController],
  providers: [DocumentosFiscaisService, ImportacaoService, ContabilizacaoService],
  exports: [DocumentosFiscaisService, ContabilizacaoService],
})
export class DocumentosFiscaisModule {}
