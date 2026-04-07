import 'package:flutter/material.dart';

/// Meow App Animation Utilities (Option B Phase 1).
///
/// Pure Flutter built-in animations. Zero external dependencies.
/// Based on: 动画方案.md
///
/// Layer 1: Implicit animations (AnimatedXxx) — 80% of use cases
/// Layer 2: Explicit animations (AnimationController) — key feedback

// ========== Layer 1: Implicit Animation Helpers ==========

/// Soft fade-in wrapper. Use for cards appearing on load.
class MeowFadeIn extends StatelessWidget {
  const MeowFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final progress = delay > Duration.zero
            ? ((value - delay.inMilliseconds / (duration + delay).inMilliseconds)
                .clamp(0.0, 1.0))
            : value;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated number counter. Use for coins/exp/mood value changes.
class MeowAnimatedNumber extends StatelessWidget {
  const MeowAnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          '$prefix$val$suffix',
          style: style,
        );
      },
    );
  }
}

/// Soft progress bar with animation. Use for exp/level progress.
class MeowAnimatedProgress extends StatelessWidget {
  const MeowAnimatedProgress({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 800),
  });

  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFF0E6D8),
            borderRadius: radius,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animValue,
            child: Container(
              decoration: BoxDecoration(
                color: color ?? const Color(0xFFFF8C42),
                borderRadius: radius,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========== Layer 2: Explicit Animation Helpers ==========

/// Breathing animation mixin. Use for cat avatar gentle pulsing.
///
/// Add to a StatefulWidget with TickerProviderStateMixin:
/// ```dart
/// class _MyState extends State<MyWidget> with TickerProviderStateMixin {
///   late final breathingController = createBreathingController(this);
///   // Use breathingController.value for scale
/// }
/// ```
AnimationController createBreathingController(
  TickerProvider vsync, {
  Duration period = const Duration(milliseconds: 3000),
}) {
  return AnimationController(
    vsync: vsync,
    duration: period,
  )..repeat(reverse: true);
}

/// Bounce animation for button press feedback.
class MeowBounceButton extends StatefulWidget {
  const MeowBounceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<MeowBounceButton> createState() => _MeowBounceButtonState();
}

class _MeowBounceButtonState extends State<MeowBounceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 0.05,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _controller.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _controller.reverse();
              widget.onPressed();
            }
          : null,
      onTapCancel: widget.enabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - _controller.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ========== Page Transition ==========

/// Soft page transition — fade + slight slide up.
/// Use instead of default MaterialPageRoute for warmer feel.
Route<T> meowPageRoute<T>({
  required Widget page,
  required RouteSettings settings,
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
