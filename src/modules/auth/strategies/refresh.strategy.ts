import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
@Injectable()
export class RefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(c: ConfigService) {
    super({ jwtFromRequest: ExtractJwt.fromBodyField('refreshToken'), secretOrKey: c.get<string>('jwt.refreshSecret') });
  }
  async validate(p: any) { return { id: p.sub, tenantId: p.tenantId }; }
}
