/**
 * 需求 23 Phase A2 — Auth module
 *
 * Exports AuthService + AuthGuard so other modules can apply guards
 * to their controllers (Phase A3+).
 */

import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthGuard } from './auth.guard';

@Module({
  controllers: [AuthController],
  providers: [AuthService, AuthGuard],
  exports: [AuthService, AuthGuard],
})
export class AuthModule {}
