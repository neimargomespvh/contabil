import { Module } from '@nestjs/common';
import { CentrosCustoController } from './centros-custo.controller';
import { CentrosCustoService } from './centros-custo.service';

@Module({
  controllers: [CentrosCustoController],
  providers: [CentrosCustoService],
  exports: [CentrosCustoService],
})
export class CentrosCustoModule {}
