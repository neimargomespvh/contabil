import { IsEmail, IsString, MinLength, Length } from 'class-validator';
export class RegisterDto {
  @IsString() nome: string;
  @IsEmail() email: string;
  @IsString() @MinLength(8) senha: string;
  @IsString() nomeTenant: string;
  @IsString() @Length(14,14) cnpjTenant: string;
}
