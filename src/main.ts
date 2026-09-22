import './common/utils/bigint-serializer';
import { NestFactory, Reflector } from '@nestjs/core';
import { ValidationPipe, ClassSerializerInterceptor, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { PrismaExceptionFilter } from './common/filters/prisma-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn', 'log'] });
  const config = app.get(ConfigService);
  const port = config.get<number>('port') ?? 3000;

  app.use(helmet({ contentSecurityPolicy: false }));
  app.enableCors({ origin: config.get<string[]>('cors.origin') ?? true, credentials: true });
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, forbidNonWhitelisted: true, transform: true,
    transformOptions: { enableImplicitConversion: true },
  }));
  app.useGlobalFilters(new PrismaExceptionFilter(), new HttpExceptionFilter());
  app.useGlobalInterceptors(new LoggingInterceptor(), new ClassSerializerInterceptor(app.get(Reflector)));

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Sistema Contábil API').setDescription('API multitenant').setVersion('1.0').addBearerAuth().build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, swaggerConfig));

  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 API em http://localhost:${port}/api/v1`);
  logger.log(`📚 Swagger em http://localhost:${port}/docs`);
}
bootstrap().catch((e) => { console.error('❌', e); process.exit(1); });
