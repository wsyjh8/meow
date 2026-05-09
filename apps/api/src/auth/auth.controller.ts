/**
 * 需求 23 Phase A2 — Auth controller
 *
 * Routes:
 *   POST /auth/register
 *   POST /auth/login
 *   POST /auth/guest
 *   GET  /auth/me        (AuthGuard required)
 *   POST /auth/bind      (AuthGuard required, must be guest)
 *   POST /auth/logout    (AuthGuard tolerated; client clears token)
 *
 * References:
 *   docs/design/plan-023-用户系统与用户数据隔离-v2.md §3.1 / §4.3
 */

import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthGuard } from './auth.guard';
import { CurrentUser } from './current-user.decorator';
import { RequestUser } from './auth.guard';
import { BindDto, GuestDto, LoginDto, RegisterDto } from './auth.types';

@Controller('auth')
@UsePipes(new ValidationPipe({ whitelist: true, transform: true }))
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.OK)
  register(@Body() dto: RegisterDto) {
    return this.authService.register({
      email: dto.email,
      password: dto.password,
      nickname: dto.nickname,
    });
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login({ email: dto.email, password: dto.password });
  }

  @Post('guest')
  @HttpCode(HttpStatus.OK)
  guest(@Body() dto: GuestDto) {
    return this.authService.startGuest({ device_id: dto.device_id });
  }

  @Get('me')
  @UseGuards(AuthGuard)
  me(@CurrentUser() user: RequestUser) {
    return this.authService.getMe(user.id);
  }

  @Post('bind')
  @HttpCode(HttpStatus.OK)
  @UseGuards(AuthGuard)
  bind(@Body() dto: BindDto, @CurrentUser() user: RequestUser) {
    return this.authService.bindGuest({
      currentUserId: user.id,
      currentUserType: user.type,
      email: dto.email,
      password: dto.password,
    });
  }

  /**
   * Stateless logout: client deletes its own token.
   * Server has no token blacklist in v1 (D3 — no refresh tokens, no
   * server-side session). The endpoint exists so clients have a single
   * "log me out" call site and can attach hooks (audit, telemetry) later.
   */
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logout() {
    return { status: 'ok' };
  }
}
