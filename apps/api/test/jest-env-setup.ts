/**
 * Jest environment setup for e2e tests.
 * Forces JSON persistence backend for test isolation.
 */
process.env.PERSISTENCE_BACKEND = 'json';
