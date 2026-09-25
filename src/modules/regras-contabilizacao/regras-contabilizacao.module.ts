import { Module } from '@nestjs/common';
import { RegrasContabilizacaoController } from './regras-contabilizacao.controller';
import { RegrasContabilizacaoService } from './regras-contabilizacao.service';
import { CondicaoValidator } from './validators/condicao.validator';

@Module({
  controllers: [RegrasContabilizacaoController],
  providers: [RegrasContabilizacaoService, CondicaoValidator],
  exports: [RegrasContabilizacaoService],
})
export class RegrasContabilizacaoModule {}
