import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RedisService } from '../../infra/redis/redis.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}

  @Public() @Get()
  async check() {
    const checks: Record<string, 'ok' | 'fail'> = {};
    try { await this.prisma.$queryRaw`SELECT 1`; checks.database = 'ok'; }
    catch { checks.database = 'fail'; }
    try { await this.redis.getClient().ping(); checks.redis = 'ok'; }
    catch { checks.redis = 'fail'; }
    const healthy = Object.values(checks).every((v) => v === 'ok');
    return { status: healthy ? 'healthy' : 'degraded', timestamp: new Date().toISOString(), uptime: process.uptime(), checks };
  }

  @Public() @Get('ready') ready() { return { status: 'ready' }; }
  @Public() @Get('live') live() { return { status: 'alive' }; }
}
