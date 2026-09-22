import { Module } from '@nestjs/common';
import { LancamentosController } from './lancamentos.controller';
import { LancamentosService } from './lancamentos.service';
import { PartidasDobradasValidator } from './validators/partidas-dobradas.validator';
@Module({
  controllers: [LancamentosController],
  providers: [LancamentosService, PartidasDobradasValidator],
  exports: [LancamentosService],
})
export class LancamentosModule {}
