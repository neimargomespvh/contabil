import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';

@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const url = new URL(config.get<string>('redis.url')!);
        return {
          connection: {
            host: url.hostname,
            port: parseInt(url.port || '6379', 10),
            password: url.password || undefined,
          },
        };
      },
    }),
    BullModule.registerQueue(
      { name: 'xml-import' }, { name: 'ofx-import' },
      { name: 'apuracao' }, { name: 'relatorio' },
    ),
  ],
  exports: [BullModule],
})
export class QueueModule {}
