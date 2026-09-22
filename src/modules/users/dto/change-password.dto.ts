import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class ChangePasswordDto {
  @ApiProperty()
  @IsString()
  @MinLength(8)
  senhaAtual: string;

  @ApiProperty()
  @IsString()
  @MinLength(8)
  novaSenha: string;
}
