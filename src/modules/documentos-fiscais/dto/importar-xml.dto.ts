import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, IsUUID, MinLength } from 'class-validator';

export class ImportarXmlDto {
  @ApiProperty({ description: 'ID da empresa à qual o documento pertence' })
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Conteúdo do XML como string' })
  @IsString()
  @MinLength(50)
  xml: string;

  @ApiPropertyOptional({
    description: 'Se true, contabiliza automaticamente ao importar',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  contabilizarAutomaticamente?: boolean = true;

  @ApiPropertyOptional({
    description: 'Se true, importa mesmo se já existir (atualiza)',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  sobrescrever?: boolean = false;
}
