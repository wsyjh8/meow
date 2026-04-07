/**
 * Persistence failure response helper (Option A closeout patch).
 *
 * Generates a structured error when PG persistence fails.
 */

export function persistenceFailureResponse(err: any) {
  return {
    ok: false,
    error: {
      code: 'PERSISTENCE_FAILURE',
      message: 'The operation completed in memory but failed to persist. The result should not be trusted.',
      retryable: true,
      details: {
        persistence_failed: true,
        original_error: err?.message || String(err),
      },
    },
  };
}
