import {
  Controller,
  Get,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  NotFoundException,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

export interface StartSessionDto {
  session_minutes_target?: number;
  session_id?: string;
}

/**
 * Sessions controller (Phase 3).
 *
 * Handles session start/finish/validation state chain.
 *
 * Frozen rules:
 * - session_status and session_validation_status are separate
 * - started / ended != valid
 * - Only after validation can we get valid or invalid
 *
 * 需求 23 Phase A4-α: AuthGuard required; user_id sourced from token.
 * Owner-check enforced inside dev-store.finishSession / getSession —
 * looking up another user's session returns 404 (not 403, to prevent
 * entity ID enumeration).
 */
@Controller('sessions')
@UseGuards(AuthGuard)
export class SessionsController {
  /**
   * POST /api/v1/sessions
   *
   * Start a new session.
   */
  @Post()
  @HttpCode(HttpStatus.OK)
  async startSession(
    @Body() dto: StartSessionDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new Error('X-Idempotency-Key header is required');
    }

    const minutesTarget = dto.session_minutes_target ?? 15;
    const result = repositories.session.startSession(user.id, minutesTarget, idempotencyKey, dto.session_id);

    await repositories.ensurePersisted();

    return {
      session_id: result.session.session_id,
      session_status: result.session.session_status,
      session_validation_status: result.session.session_validation_status,
      session_minutes_target: result.session.session_minutes_target,
      started_at: result.session.started_at,
      already_exists: result.alreadyExists,
    };
  }

  /**
   * POST /api/v1/sessions/:session_id/finish
   *
   * Finish a session and enter validation state chain.
   */
  @Post(':sessionId/finish')
  @HttpCode(HttpStatus.OK)
  async finishSession(
    @Param('sessionId') sessionId: string,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new Error('X-Idempotency-Key header is required');
    }

    try {
      const result = repositories.session.finishSession(user.id, sessionId, idempotencyKey);

      await repositories.ensurePersisted();

      return {
        session_id: result.session.session_id,
        session_status: result.session.session_status,
        session_validation_status: result.session.session_validation_status,
        effective_learning_count: result.session.effective_learning_count,
        effective_review_count: result.session.effective_review_count,
        session_minutes_target: result.session.session_minutes_target,
        started_at: result.session.started_at,
        ended_at: result.session.ended_at,
        duration_seconds: result.session.duration_seconds,
        already_exists: result.alreadyExists,
      };
    } catch (err: any) {
      // Owner-check failure or genuinely missing → 404
      if (err?.message?.includes('Session not found')) {
        throw new NotFoundException(`Session not found: ${sessionId}`);
      }
      throw err;
    }
  }

  /**
   * GET /api/v1/sessions/:session_id
   *
   * Query session status.
   */
  @Get(':sessionId')
  getSession(
    @Param('sessionId') sessionId: string,
    @CurrentUser() user: RequestUser,
  ) {
    const session = repositories.session.getSession(user.id, sessionId);

    if (!session) {
      throw new NotFoundException(`Session not found: ${sessionId}`);
    }

    return {
      session_id: session.session_id,
      session_status: session.session_status,
      session_validation_status: session.session_validation_status,
      session_minutes_target: session.session_minutes_target,
      started_at: session.started_at,
      ended_at: session.ended_at,
      duration_seconds: session.duration_seconds,
      effective_learning_count: session.effective_learning_count,
      effective_review_count: session.effective_review_count,
    };
  }
}
