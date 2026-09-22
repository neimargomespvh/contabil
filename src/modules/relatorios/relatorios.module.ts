import { Module } from '@nestjs/common';
import { RelatoriosController } from './relatorios.controller';
import { RelatoriosService } from './relatorios.service';
import { BalanceteGenerator } from './generators/balancete.generator';
import { BalancoGenerator } from './generators/balanco.generator';
import { DreGenerator } from './generators/dre.generator';
import { RazaoGenerator } from './generators/razao.generator';
import { LivroDiarioGenerator } from './generators/livro-diario.generator';
import { FluxoCaixaGenerator } from './generators/fluxo-caixa.generator';
import { PdfExporter } from './exporters/pdf.exporter';
import { ExcelExporter } from './exporters/excel.exporter';

@Module({
  controllers: [RelatoriosController],
  providers: [
    RelatoriosService,
    BalanceteGenerator,
    BalancoGenerator,
    DreGenerator,
    RazaoGenerator,
    LivroDiarioGenerator,
    FluxoCaixaGenerator,
    PdfExporter,
    ExcelExporter,
  ],
  exports: [RelatoriosService],
})
export class RelatoriosModule {}
