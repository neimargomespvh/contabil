import { PartialType } from '@nestjs/swagger';
import { CreateCentroCustoDto } from './create-centro.dto';

export class UpdateCentroCustoDto extends PartialType(CreateCentroCustoDto) {}
