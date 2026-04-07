/**
 * Persistence failure exception filter (Option A.1 H3).
 *
 * Catches PG persistence errors thrown by ensurePersisted() and returns
 * a structured 500 response instead of a generic NestJS error.
 *
 * This filter distinguishes persistence failures from other server errors,
 * enabling UI to show "save failed" rather than generic "server error".
 */

import { ExceptionFilter, Catch, ArgumentsHost, HttpStatus } from '@nestjs/common';
import { Response } from 'express';

/**
 * Custom error class for persistence failures.
 * Thrown by DevStore.saveToDiskAsync() when PG save fails.
 */
export class PersistenceFailureError extends Error {
  constructor(public readonly originalError: Error) {
    super(`Persistence failure: ${originalError.message}`);
    this.name = 'PersistenceFailureError';
  }
}

@Catch()
export class PersistenceFailureFilter implements ExceptionFilter {
  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    // Check if this is a persistence failure (from ensurePersisted / saveToDiskAsync)
    const isPersistenceError =
      exception instanceof PersistenceFailureError ||
      exception?.message?.includes('Persistence failure') ||
      exception?.message?.includes('PG save failed') ||
      exception?.code === '42P01' || // relation does not exist
      exception?.code === '23503' || // FK violation
      exception?.code === '23505' || // unique violation
      exception?.severity === '错误'; // Chinese PG error

    if (isPersistenceError && !response.headersSent) {
      return response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
        ok: false,
        error: {
          code: 'PERSISTENCE_FAILURE',
          message: 'The operation completed in memory but failed to persist to database. The result should not be trusted.',
          retryable: true,
          details: {
            persistence_failed: true,
            original_error: exception?.originalError?.message || exception?.message || 'Unknown persistence error',
          },
        },
      });
    }

    // Not a persistence error — let NestJS default handling take over
    // Re-throw so other filters / default handler can process it
    if (!response.headersSent) {
      const status = exception?.getStatus?.() || HttpStatus.INTERNAL_SERVER_ERROR;
      const message = exception?.message || 'Internal server error';
      return response.status(status).json({
        statusCode: status,
        message,
      });
    }
  }
}
