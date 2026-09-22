import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.USUARIO_VER)
  @ApiOperation({ summary: 'Lista usuários do tenant' })
  listar(@CurrentTenant() tenantId: string) {
    return this.service.listar(tenantId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.USUARIO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  @ApiOperation({ summary: 'Cria novo usuário' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateUserDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Post(':id/ativar')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  ativar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.ativar(t, id);
  }

  @Post(':id/desativar')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  desativar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.desativar(t, id);
  }

  @Post(':id/resetar-senha')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  @ApiOperation({ summary: 'Reseta a senha do usuário (retorna senha temporária)' })
  resetarSenha(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.resetarSenha(t, id);
  }

  @Put('me/senha')
  @ApiOperation({ summary: 'Usuário altera a própria senha' })
  alterarMinhaSenha(
    @CurrentTenant() t: string,
    @CurrentUser('id') userId: string,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.service.alterarSenha(t, userId, dto);
  }
}
