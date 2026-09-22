import { Module } from '@nestjs/common';
import { ContasController, PlanoContasController } from './plano-contas.controller';
import { PlanoContasService } from './plano-contas.service';

@Module({
  controllers: [PlanoContasController, ContasController],
  providers: [PlanoContasService],
  exports: [PlanoContasService],
})
export class PlanoContasModule {}
