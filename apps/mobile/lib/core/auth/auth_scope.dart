/// 需求 23 Phase B — AuthScope (InheritedNotifier of AuthController).
///
/// Lightweight DI without bringing in Provider/Riverpod/BLoC. Widgets call
/// `AuthScope.of(context)` to read AuthController; using `AuthScope.of` in
/// `build()` automatically subscribes the widget to AuthController's
/// `notifyListeners` events.
///
/// plan v2 §6.1 architecture choice: ChangeNotifier + InheritedNotifier
/// (no new deps, compatible with existing StatefulWidget-only code).
///
/// 需求 23 Phase C PR-C-β: per-user repository / service construction
/// in widgets needs a `currentUserId` at any depth. Tests that pump a
/// widget without an AuthScope (legacy widget tests targeting individual
/// pages) would otherwise crash on the assert here. To keep tests
/// boilerplate-free, [maybeRead] returns null when no scope is found and
/// [currentUserIdOf] falls back to [AuthStorage.pendingLocalGuestUserId].
/// Real production paths always have an AuthScope (wired in main.dart
/// after AuthBootstrap), so the fallback path is exercised exclusively
/// by widget-test scaffolding.
library;

import 'package:flutter/widgets.dart';

import 'auth_controller.dart';
import 'auth_storage.dart';

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Read the AuthController. Subscribes the calling widget to rebuilds
  /// on AuthController state changes.
  static AuthController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.of() called without a parent AuthScope');
    return scope!.notifier!;
  }

  /// Read the AuthController without subscribing to rebuilds. Use in
  /// callbacks (button handlers etc.) where you only need a one-shot read.
  static AuthController read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.read() called without a parent AuthScope');
    return scope!.notifier!;
  }

  /// Test-friendly: read the AuthController if present, else null.
  /// Use [currentUserIdOf] when only the bound user_id is needed —
  /// legacy widget tests pump pages directly without an AuthScope and
  /// shouldn't have to scaffold one for code that only wants a userId.
  static AuthController? maybeRead(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    return scope?.notifier;
  }

  /// Convenience: the bound user_id, falling back to
  /// [AuthStorage.pendingLocalGuestUserId] when no AuthScope is in the
  /// widget tree (typical for legacy widget tests). PR-C-β widget call
  /// sites should prefer this over `AuthScope.read(context).currentUserId`
  /// when they only need the id for service/repository construction.
  static String currentUserIdOf(BuildContext context) {
    return maybeRead(context)?.currentUserId ??
        AuthStorage.pendingLocalGuestUserId;
  }
}
