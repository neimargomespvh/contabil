import { Module } from '@nestjs/common';
import { ApuracoesController } from './apuracoes.controller';
import { ApuracoesService } from './apuracoes.service';
import { SimplesCalculator } from './calculators/simples.calculator';
import { PresumidoCalculator } from './calculators/presumido.calculator';
import { MeiCalculator } from './calculators/mei.calculator';
import { GuiaGenerator } from './guias/guia.generator';

@Module({
  controllers: [ApuracoesController],
  providers: [
    ApuracoesService,
    SimplesCalculator,
    PresumidoCalculator,
    MeiCalculator,
    GuiaGenerator,
  ],
  exports: [ApuracoesService],
})
export class ApuracoesModule {}
