/// 需求 23 Phase B — Startup orchestration for the auth layer.
///
/// Composes: SharedPreferences + DeviceInfoService + AuthStorage + AuthApi
/// + AuthController. Returns a ready-to-use AuthController + the
/// auth-aware http.Client that ApiClient should adopt.
///
/// Wire this once from `main.dart` before runApp:
///
///   final boot = await AuthBootstrap.run(prefs, deviceInfoService);
///   runApp(MeowApp(authController: boot.controller, authClient: boot.httpClient));
///
/// References:
///   - plan-023-用户系统与用户数据隔离-v2.md §7.4 (startup order)
///   - plan-023-用户系统与用户数据隔离-v2.md §6.3 (single-ID design)
///   - sp-keys-audit.md §7.3 (target startup sequence)
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../device/device_info_service.dart';
import 'auth_api.dart';
import 'auth_controller.dart';
import 'auth_http_client.dart';
import 'auth_storage.dart';

class AuthBootstrapResult {
  final AuthController controller;
  final AuthHttpClient httpClient;
  final AuthStorage storage;

  const AuthBootstrapResult({
    required this.controller,
    required this.httpClient,
    required this.storage,
  });
}

class AuthBootstrap {
  /// Resolve initial user binding and return a ready controller + client.
  ///
  /// Failures (network down, server unreachable, secure storage missing)
  /// degrade gracefully: controller ends in `offlineGuest` state with a
  /// `pending-local-guest` placeholder user_id; runApp() still launches.
  static Future<AuthBootstrapResult> run({
    required SharedPreferences prefs,
    required DeviceInfoService deviceInfoService,
    AuthApi? apiOverride,
    Duration networkTimeout = const Duration(seconds: 8),
  }) async {
    final storage = await AuthStorage.open(prefs);
    final api = apiOverride ?? AuthApi();

    final controller = AuthController(storage: storage, api: api);
    final httpClient = AuthHttpClient(
      storage: storage,
      controller: controller,
    );

    final deviceId = await deviceInfoService.getDeviceId(prefs);
    await controller.bootstrap(
      deviceId: deviceId,
      networkTimeout: networkTimeout,
    );

    return AuthBootstrapResult(
      controller: controller,
      httpClient: httpClient,
      storage: storage,
    );
  }
}
