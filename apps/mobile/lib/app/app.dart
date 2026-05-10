import 'package:flutter/material.dart';
import '../core/auth/auth.dart';
import '../core/router/app_router.dart';
import '../core/storage/auto_backup_service.dart';
import '../spec/pages/spec_shell.dart';
import '../spec/theme/tokens.dart';

/// Global RouteObserver — used by StudyPage (and any other page that
/// needs to react to route-pop transitions, e.g. "settings was just
/// dismissed, recheck dailyGoal"). Wired into MaterialApp's
/// navigatorObservers below.
///
/// Pages opt in via `with RouteAware` and a subscribe/unsubscribe pair
/// in didChangeDependencies / dispose.
final RouteObserver<PageRoute<dynamic>> studyPageRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// Root application widget.
///
/// Responsibilities:
///   - Configure MaterialApp theme and routing.
///   - Observe app lifecycle to trigger auto-backup on background.
///
/// Auto-backup policy:
///   When app moves to [AppLifecycleState.paused] (background/minimized),
///   [AutoBackupService.triggerIfNeeded()] is called fire-and-forget.
///   The service only runs if >30min since the last backup.
///   Failures are silent — the user can always backup manually from Settings.
class MeowApp extends StatefulWidget {
  /// 需求 23 Phase B: AuthController is constructed by AuthBootstrap in
  /// main.dart and injected here. Wrapped in an [AuthScope] so any
  /// widget can call `AuthScope.of(context)`.
  ///
  /// Optional for back-compat with code paths (e.g. legacy tests) that
  /// don't yet wire AuthBootstrap; if null, widgets that depend on
  /// AuthScope must guard the absence.
  final AuthController? authController;

  const MeowApp({super.key, this.authController});

  @override
  State<MeowApp> createState() => _MeowAppState();
}

class _MeowAppState extends State<MeowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App going to background — trigger auto-backup (fire-and-forget).
      AutoBackupService.triggerIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: '背单词喵喵',
      debugShowCheckedModeBanner: false,
      // SPEC theme: warm beige canvas, no shadows
      theme: ThemeData(
        scaffoldBackgroundColor: SpecBg.canvas,
        fontFamily: 'PingFang SC',
        colorSchemeSeed: SpecBrand.purple,
        useMaterial3: true,
      ),
      navigatorObservers: [studyPageRouteObserver],
      // New SPEC shell as home, old routes still accessible for navigation
      home: const SpecShell(),
      onGenerateRoute: AppRouter.generateRoute,
    );

    // 需求 23 Phase B: wrap with AuthScope so descendants can resolve
    // the current user via AuthScope.of(context). When authController is
    // null (legacy / test path), skip the wrap — descendants that depend
    // on AuthScope will assert.
    if (widget.authController != null) {
      return AuthScope(controller: widget.authController!, child: app);
    }
    return app;
  }
}
