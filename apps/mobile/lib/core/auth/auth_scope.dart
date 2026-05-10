/// 需求 23 Phase B — AuthScope (InheritedNotifier of AuthController).
///
/// Lightweight DI without bringing in Provider/Riverpod/BLoC. Widgets call
/// `AuthScope.of(context)` to read AuthController; using `AuthScope.of` in
/// `build()` automatically subscribes the widget to AuthController's
/// `notifyListeners` events.
///
/// plan v2 §6.1 architecture choice: ChangeNotifier + InheritedNotifier
/// (no new deps, compatible with existing StatefulWidget-only code).
library;

import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

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
}
