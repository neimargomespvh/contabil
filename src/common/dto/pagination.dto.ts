import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class PaginationDto {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page: number = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit: number = 20;
  @IsOptional() @IsString() orderBy?: string = 'createdAt';
  @IsOptional() @IsString() order: 'asc' | 'desc' = 'desc';
  get skip(): number { return (this.page - 1) * this.limit; }
}

export interface PaginatedResult<T> {
  data: T[];
  meta: { total: number; page: number; limit: number; totalPages: number };
}

export function paginar<T>(data: T[], total: number, page: number, limit: number): PaginatedResult<T> {
  return { data, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
}
