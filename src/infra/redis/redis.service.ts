import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private readonly client: Redis;
  private readonly prefix: string;

  constructor(config: ConfigService) {
    this.prefix = config.get<string>('redis.prefix') ?? 'contabil:';
    this.client = new Redis(config.get<string>('redis.url')!, { maxRetriesPerRequest: 3 });
    this.client.on('connect', () => this.logger.log('✅ Redis conectado'));
    this.client.on('error', (e) => this.logger.error('Redis erro', e.message));
  }
  async onModuleDestroy() { await this.client.quit(); }
  private k(key: string) { return `${this.prefix}${key}`; }
  async get<T = any>(key: string): Promise<T | null> {
    const v = await this.client.get(this.k(key));
    return v ? JSON.parse(v) as T : null;
  }
  async set(key: string, value: any, ttl?: number): Promise<void> {
    const p = JSON.stringify(value);
    if (ttl) await this.client.set(this.k(key), p, 'EX', ttl);
    else await this.client.set(this.k(key), p);
  }
  async del(key: string): Promise<void> { await this.client.del(this.k(key)); }
  getClient(): Redis { return this.client; }
}
