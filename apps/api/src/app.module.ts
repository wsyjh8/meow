import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { ConfigModule } from './config/config.module';
import { RoutesModule } from './routes/routes.module';
import { AuthModule } from './auth/auth.module';
import { MaintenanceGuardMiddleware } from './middleware/maintenance.guard';

@Module({
  imports: [
    ConfigModule,
    AuthModule,
    RoutesModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // Maintenance guard blocks ALL write requests when MAINTENANCE_MODE=true
    consumer.apply(MaintenanceGuardMiddleware).forRoutes('*');
  }
}
