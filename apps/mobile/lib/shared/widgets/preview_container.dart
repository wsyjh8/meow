import 'package:flutter/material.dart';
import '../theme.dart';

/// PreviewContainer — Top preview area for Customize and Meow Home.
///
/// Displays current cat/room preview with warm gradient background.
class PreviewContainer extends StatelessWidget {
  const PreviewContainer({
    super.key,
    required this.child,
    this.height = 200,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MeowColors.catOrange.withValues(alpha: 0.15),
            MeowColors.background,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(MeowRadius.xl),
          bottomRight: Radius.circular(MeowRadius.xl),
        ),
      ),
      child: child,
    );
  }
}
