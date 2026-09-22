import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    const isHttp = exception instanceof HttpException;
    const status = isHttp
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const responseBody = isHttp
      ? (exception.getResponse() as any)
      : { message: 'Erro interno do servidor' };

    const message =
      typeof responseBody === 'string'
        ? responseBody
        : responseBody.message ?? 'Erro';

    const payload = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: req.url,
      method: req.method,
      message,
      ...(Array.isArray(message) ? {} : {}),
    };

    if (status >= 500) {
      this.logger.error(
        `${req.method} ${req.url} - ${status}`,
        (exception as Error)?.stack,
      );
    }

    res.status(status).json(payload);
  }
}