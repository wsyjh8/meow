/**
 * 需求 23 Phase A2 — Auth types & DTOs
 *
 * References:
 *   docs/design/plan-023-用户系统与用户数据隔离-v2.md §3.1 / §6.2
 *   docs/design/audits/controller-auth-audit.md
 */

import {
  IsEmail,
  IsString,
  Length,
  IsOptional,
  Matches,
} from 'class-validator';

export type AccountType = 'guest' | 'registered';

export interface UserRow {
  id: string;
  email: string | null;
  nickname: string;
  account_type: AccountType;
  device_id: string | null;
  created_at: string;
  last_login_at: string | null;
}

/** Token payload signed by HS256. */
export interface JwtPayload {
  sub: string;          // user_id
  type: AccountType;
  iat: number;          // issued at (seconds)
  exp: number;          // expires at (seconds)
}

/** Sanitized user shape returned to clients (never includes password_hash). */
export interface AuthUser {
  id: string;
  email: string | null;
  nickname: string;
  account_type: AccountType;
  created_at: string;
}

export interface AuthResponse {
  user: AuthUser;
  token: string;
  /** Seconds-since-epoch when token expires. Convenience for clients. */
  expires_at: number;
}

// ========== DTOs (validated by ValidationPipe) ==========

export class RegisterDto {
  @IsEmail({}, { message: 'Invalid email address' })
  email!: string;

  @IsString()
  @Length(8, 64, { message: 'Password must be 8-64 chars' })
  password!: string;

  @IsOptional()
  @IsString()
  @Length(1, 100)
  nickname?: string;
}

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(1, 64)
  password!: string;
}

export class GuestDto {
  /**
   * Client device identifier (UUID v4). Used for /auth/guest idempotency:
   * same device_id returns the same guest user_id.
   */
  @IsString()
  @Length(8, 128)
  @Matches(/^[A-Za-z0-9_-]+$/, { message: 'device_id contains invalid chars' })
  device_id!: string;
}

export class BindDto {
  /** Email/password are required; the current guest token in Authorization
   *  identifies which guest row to upgrade. */
  @IsEmail()
  email!: string;

  @IsString()
  @Length(8, 64)
  password!: string;
}
