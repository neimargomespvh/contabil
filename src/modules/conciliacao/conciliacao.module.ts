import { Module } from '@nestjs/common';
import { ConciliacaoController } from './conciliacao.controller';
import { ConciliacaoService } from './conciliacao.service';
import { MatchService } from './services/match.service';
import { ContasBancariasModule } from '../contas-bancarias/contas-bancarias.module';

@Module({
  imports: [ContasBancariasModule],
  controllers: [ConciliacaoController],
  providers: [ConciliacaoService, MatchService],
  exports: [ConciliacaoService],
})
export class ConciliacaoModule {}
