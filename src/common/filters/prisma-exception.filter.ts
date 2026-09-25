import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Request, Response } from 'express';

@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(exception: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Erro ao processar requisição no banco de dados';
    let error = 'PrismaError';

    switch (exception.code) {
      case 'P2002': {
        status = HttpStatus.CONFLICT;
        const target = (exception.meta?.target as string[]) ?? [];
        message = `Registro duplicado: ${target.join(', ')}`;
        error = 'UniqueConstraintViolation';
        break;
      }
      case 'P2003': {
        status = HttpStatus.BAD_REQUEST;
        message = 'Violação de chave estrangeira (registro relacionado inexistente)';
        error = 'ForeignKeyViolation';
        break;
      }
      case 'P2025': {
        status = HttpStatus.NOT_FOUND;
        message = 'Registro não encontrado';
        error = 'RecordNotFound';
        break;
      }
      case 'P2014': {
        status = HttpStatus.BAD_REQUEST;
        message = 'Violação de relação obrigatória';
        error = 'RequiredRelationViolation';
        break;
      }
      default: {
        this.logger.error(
          `Prisma ${exception.code} em ${req.method} ${req.url}`,
          exception.stack,
        );
      }
    }

    res.status(status).json({
      success: false,
      statusCode: status,
      message,
      error,
      path: req.url,
      timestamp: new Date().toISOString(),
    });
  }
}
