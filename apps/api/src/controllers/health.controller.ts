import { Controller, Get } from '@nestjs/common';
import {
  isMaintenanceMode,
  isReadOnlyMode,
  isTemporarilyUnavailable,
  isWriteBlocked,
} from '../middleware/maintenance.guard';

@Controller('health')
export class HealthController {
  @Get()
  health() {
    const writeBlocked = isWriteBlocked();
    let status = 'ok';
    if (isMaintenanceMode()) status = 'maintenance';
    else if (isReadOnlyMode()) status = 'read_only';
    else if (isTemporarilyUnavailable()) status = 'temporarily_unavailable';

    return {
      status,
      persistence_backend: process.env.PERSISTENCE_BACKEND || 'pg',
      write_blocked: writeBlocked,
      degraded_state: {
        maintenance: isMaintenanceMode(),
        read_only: isReadOnlyMode(),
        temporarily_unavailable: isTemporarilyUnavailable(),
      },
      timestamp: new Date().toISOString(),
    };
  }
}
