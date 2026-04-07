import { Injectable } from '@nestjs/common';
import { AppConfig } from '../types';

@Injectable()
export class ConfigService {
  private readonly config: AppConfig;

  constructor() {
    this.config = {
      port: parseInt(process.env.PORT || '3000', 10),
      nodeEnv: process.env.NODE_ENV || 'development',
      corsOrigin: process.env.CORS_ORIGIN || '*',
    };
  }

  get port(): number {
    return this.config.port;
  }

  get nodeEnv(): string {
    return this.config.nodeEnv;
  }

  get corsOrigin(): string {
    return this.config.corsOrigin;
  }
}
