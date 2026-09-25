import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

interface ErrorResponse {
  success: false;
  statusCode: number;
  message: string | string[];
  error: string;
  path: string;
  timestamp: string;
  requestId?: string;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Erro interno do servidor';
    let error = 'InternalServerError';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const response = exception.getResponse();

      if (typeof response === 'string') {
        message = response;
      } else if (typeof response === 'object' && response !== null) {
        const resp = response as Record<string, any>;
        message = resp.message ?? message;
        error = resp.error ?? exception.name;
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      error = exception.name;
    }

    const requestId = (req as any).id ?? req.headers['x-request-id'];

    const body: ErrorResponse = {
      success: false,
      statusCode: status,
      message,
      error,
      path: req.url,
      timestamp: new Date().toISOString(),
      ...(typeof requestId === 'string' && { requestId }),
    };

    // Log apenas erros 5xx (erros do cliente são esperados)
    if (status >= 500) {
      const user = (req as any).user;
      this.logger.error(
        `${req.method} ${req.url} - ${status} - tenant=${user?.tenantId ?? '-'} user=${user?.id ?? '-'} - ${error}: ${
          Array.isArray(message) ? message.join('; ') : message
        }`,
        exception instanceof Error ? exception.stack : undefined,
      );
    }

    res.status(status).json(body);
  }
}
