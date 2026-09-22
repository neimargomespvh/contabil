import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus, Logger } from '@nestjs/common';
import {
  PrismaClientKnownRequestError,
  PrismaClientValidationError,
  PrismaClientInitializationError,
} from '@prisma/client/runtime/library';
import { Response } from 'express';

@Catch(PrismaClientKnownRequestError, PrismaClientValidationError, PrismaClientInitializationError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();
    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Erro de banco de dados';

    if (exception instanceof PrismaClientKnownRequestError) {
      switch (exception.code) {
        case 'P2002':
          status = HttpStatus.CONFLICT;
          message = `Registro duplicado: ${(exception.meta?.target as string[])?.join(', ') ?? ''}`;
          break;
        case 'P2003':
          status = HttpStatus.BAD_REQUEST;
          message = 'Violação de chave estrangeira';
          break;
        case 'P2025':
          status = HttpStatus.NOT_FOUND;
          message = 'Registro não encontrado';
          break;
        default:
          message = `Erro Prisma ${exception.code}`;
      }
    } else if (exception instanceof PrismaClientValidationError) {
      status = HttpStatus.BAD_REQUEST; message = 'Dados inválidos';
    } else if (exception instanceof PrismaClientInitializationError) {
      message = 'Erro ao conectar no banco';
    }

    this.logger.error(message, (exception as Error)?.stack);
    res.status(status).json({ statusCode: status, timestamp: new Date().toISOString(), message });
  }
}
