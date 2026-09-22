import { BadRequestException, Injectable } from '@nestjs/common';
import { CreatePartidaDto } from '../dto/create-partida.dto';
@Injectable()
export class PartidasDobradasValidator {
  validar(partidas: CreatePartidaDto[]): void {
    if (!partidas?.length || partidas.length < 2) throw new BadRequestException('Mínimo 2 partidas');
    const d = partidas.filter((p) => p.tipo === 'D').reduce((a, p) => a + p.valor, 0);
    const c = partidas.filter((p) => p.tipo === 'C').reduce((a, p) => a + p.valor, 0);
    if (Math.abs(d - c) > 0.01) throw new BadRequestException(`Débitos (${d}) ≠ créditos (${c})`);
    partidas.forEach((p) => {
      if (p.valor <= 0) throw new BadRequestException('Valor positivo obrigatório');
    });
  }
}
