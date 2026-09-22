import { Body, Controller, Post, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RefreshDto } from './dto/refresh.dto';
import { Public } from '../../common/decorators/public.decorator';
@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}
  @Public() @Post('login') @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) { return this.auth.login(dto); }
  @Public() @Post('register')
  register(@Body() dto: RegisterDto) { return this.auth.register(dto); }
  @Public() @Post('refresh') @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshDto) { return this.auth.refresh(dto.refreshToken); }
}
