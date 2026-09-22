import { IsString, MinLength } from 'class-validator';
export class EstornoDto { @IsString() @MinLength(5) motivo: string; }
