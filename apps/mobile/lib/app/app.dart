import 'package:flutter/material.dart';
import '../core/router/app_router.dart';
import '../spec/pages/spec_shell.dart';
import '../spec/theme/tokens.dart';

class MeowApp extends StatelessWidget {
  const MeowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '背单词喵喵',
      debugShowCheckedModeBanner: false,
      // SPEC theme: warm beige canvas, no shadows
      theme: ThemeData(
        scaffoldBackgroundColor: SpecBg.canvas,
        fontFamily: 'PingFang SC',
        colorSchemeSeed: SpecBrand.purple,
        useMaterial3: true,
      ),
      // New SPEC shell as home, old routes still accessible for navigation
      home: const SpecShell(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
