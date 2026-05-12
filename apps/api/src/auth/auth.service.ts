/**
 * 需求 23 Phase A2 — Auth service
 *
 * Owns: JWT sign/verify, bcrypt hashing, /auth/* business logic.
 *
 * Persistence: PostgreSQL (`users` table, see migration 008).
 * In-memory dev-store is NOT used here — auth is always PG-backed
 * regardless of PERSISTENCE_BACKEND, because credentials must survive
 * server restart even in dev.
 *
 * References:
 *   docs/design/plan-023-用户系统与用户数据隔离-v2.md §3.1 §6.2
 */

import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import { getPool } from '../infrastructure/postgres/client';
import {
  AccountType,
  AuthResponse,
  AuthUser,
  JwtPayload,
  UserRow,
} from './auth.types';

const BCRYPT_COST = 10; // cost=12 in plan; 10 is sufficient for v1 + faster tests
const TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60; // 30 days (D3)

@Injectable()
export class AuthService {
  // ========== JWT ==========

  private getJwtSecret(): string {
    const s = process.env.JWT_SECRET;
    if (!s || s.length < 16) {
      throw new Error(
        '[auth] JWT_SECRET is missing or too short (min 16 chars). ' +
          'Set in .env. See .env.example.',
      );
    }
    return s;
  }

  signToken(userId: string, type: AccountType): {
    token: string;
    expires_at: number;
  } {
    const now = Math.floor(Date.now() / 1000);
    const expiresAt = now + TOKEN_TTL_SECONDS;
    const payload: JwtPayload = {
      sub: userId,
      type,
      iat: now,
      exp: expiresAt,
    };
    const token = jwt.sign(payload, this.getJwtSecret(), { algorithm: 'HS256' });
    return { token, expires_at: expiresAt };
  }

  verifyToken(token: string): JwtPayload {
    try {
      const decoded = jwt.verify(token, this.getJwtSecret(), {
        algorithms: ['HS256'],
      }) as JwtPayload;
      return decoded;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  // ========== Persistence helpers ==========

  private async findUserById(id: string): Promise<UserRow | null> {
    const r = await getPool().query<UserRow>(
      `SELECT id, email, nickname, account_type, device_id,
              created_at::text, last_login_at::text
       FROM users WHERE id = $1`,
      [id],
    );
    return r.rows[0] ?? null;
  }

  private async findUserByEmail(email: string): Promise<UserRow | null> {
    const r = await getPool().query<UserRow>(
      `SELECT id, email, nickname, account_type, device_id,
              created_at::text, last_login_at::text
       FROM users WHERE LOWER(email) = LOWER($1)`,
      [email],
    );
    return r.rows[0] ?? null;
  }

  private async findGuestByDevice(deviceId: string): Promise<UserRow | null> {
    const r = await getPool().query<UserRow>(
      `SELECT id, email, nickname, account_type, device_id,
              created_at::text, last_login_at::text
       FROM users WHERE device_id = $1 AND account_type = 'guest'
       ORDER BY created_at ASC LIMIT 1`,
      [deviceId],
    );
    return r.rows[0] ?? null;
  }

  private async loadPasswordHash(id: string): Promise<string | null> {
    const r = await getPool().query<{ password_hash: string | null }>(
      'SELECT password_hash FROM users WHERE id = $1',
      [id],
    );
    return r.rows[0]?.password_hash ?? null;
  }

  private async touchLastLogin(id: string): Promise<void> {
    await getPool().query(
      'UPDATE users SET last_login_at = NOW(), updated_at = NOW() WHERE id = $1',
      [id],
    );
  }

  private toAuthUser(row: UserRow): AuthUser {
    return {
      id: row.id,
      email: row.email,
      nickname: row.nickname,
      account_type: row.account_type,
      created_at: row.created_at,
    };
  }

  // ========== Operations ==========

  async register(input: {
    email: string;
    password: string;
    nickname?: string;
  }): Promise<AuthResponse> {
    const existing = await this.findUserByEmail(input.email);
    if (existing) {
      throw new ConflictException({
        error_code: 'EMAIL_TAKEN',
        message: 'Email already registered',
      });
    }

    const id = `user-${randomUUID()}`;
    const passwordHash = await bcrypt.hash(input.password, BCRYPT_COST);
    const nickname = (input.nickname ?? 'Learner').trim() || 'Learner';

    await getPool().query(
      `INSERT INTO users (id, nickname, email, password_hash, account_type, last_login_at)
       VALUES ($1, $2, $3, $4, 'registered', NOW())`,
      [id, nickname, input.email, passwordHash],
    );

    const user = await this.findUserById(id);
    if (!user) {
      throw new Error('[auth] failed to load user after register');
    }

    const { token, expires_at } = this.signToken(user.id, 'registered');
    return { user: this.toAuthUser(user), token, expires_at };
  }

  async login(input: { email: string; password: string }): Promise<AuthResponse> {
    const user = await this.findUserByEmail(input.email);
    if (!user || user.account_type !== 'registered') {
      throw new UnauthorizedException({
        error_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }
    const hash = await this.loadPasswordHash(user.id);
    if (!hash) {
      throw new UnauthorizedException({
        error_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }
    const ok = await bcrypt.compare(input.password, hash);
    if (!ok) {
      throw new UnauthorizedException({
        error_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }
    await this.touchLastLogin(user.id);

    const { token, expires_at } = this.signToken(user.id, 'registered');
    return { user: this.toAuthUser(user), token, expires_at };
  }

  async startGuest(input: { device_id: string }): Promise<AuthResponse> {
    // Idempotent by device_id: same device returns same guest user.
    const existing = await this.findGuestByDevice(input.device_id);
    if (existing) {
      await this.touchLastLogin(existing.id);
      const { token, expires_at } = this.signToken(existing.id, 'guest');
      return { user: this.toAuthUser(existing), token, expires_at };
    }

    const id = `guest-${randomUUID()}`;
    await getPool().query(
      `INSERT INTO users (id, nickname, account_type, device_id, last_login_at)
       VALUES ($1, $2, 'guest', $3, NOW())`,
      [id, 'Learner', input.device_id],
    );

    const user = await this.findUserById(id);
    if (!user) {
      throw new Error('[auth] failed to load user after guest signup');
    }

    const { token, expires_at } = this.signToken(user.id, 'guest');
    return { user: this.toAuthUser(user), token, expires_at };
  }

  /**
   * Bind a guest account to email/password (same-row upgrade per plan v2 §6.2).
   * users.id is unchanged; account_type flips from 'guest' to 'registered'.
   * Business tables keep their original user_id — no rewrite needed.
   */
  async bindGuest(input: {
    currentUserId: string;
    currentUserType: AccountType;
    email: string;
    password: string;
  }): Promise<AuthResponse> {
    if (input.currentUserType !== 'guest') {
      throw new BadRequestException({
        error_code: 'NOT_GUEST',
        message: 'Only guest accounts can bind. Already a registered user.',
      });
    }

    const pool = getPool();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Email uniqueness check inside the txn
      const dup = await client.query(
        'SELECT 1 FROM users WHERE LOWER(email) = LOWER($1) FOR UPDATE',
        [input.email],
      );
      if (dup.rows.length > 0) {
        await client.query('ROLLBACK');
        throw new ConflictException({
          error_code: 'EMAIL_TAKEN',
          message: 'Email already registered',
        });
      }

      const passwordHash = await bcrypt.hash(input.password, BCRYPT_COST);
      const upd = await client.query(
        `UPDATE users
            SET email = $2,
                password_hash = $3,
                account_type = 'registered',
                last_login_at = NOW(),
                updated_at = NOW()
          WHERE id = $1 AND account_type = 'guest'`,
        [input.currentUserId, input.email, passwordHash],
      );
      if (upd.rowCount === 0) {
        await client.query('ROLLBACK');
        throw new NotFoundException({
          error_code: 'GUEST_NOT_FOUND',
          message: 'Current guest user no longer exists',
        });
      }

      await client.query('COMMIT');
    } catch (err) {
      try {
        await client.query('ROLLBACK');
      } catch {
        // ignore secondary rollback errors
      }
      throw err;
    } finally {
      client.release();
    }

    const user = await this.findUserById(input.currentUserId);
    if (!user) {
      throw new Error('[auth] user vanished after bind');
    }
    const { token, expires_at } = this.signToken(user.id, 'registered');
    return { user: this.toAuthUser(user), token, expires_at };
  }

  async getMe(userId: string): Promise<AuthUser> {
    const user = await this.findUserById(userId);
    if (!user) {
      throw new NotFoundException({
        error_code: 'USER_NOT_FOUND',
        message: 'Current user no longer exists',
      });
    }
    return this.toAuthUser(user);
  }
}
