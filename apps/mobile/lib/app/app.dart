import 'package:flutter/material.dart';
import '../core/router/app_router.dart';
import '../shared/theme.dart';

class MeowApp extends StatelessWidget {
  const MeowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '背单词喵喵',
      debugShowCheckedModeBanner: false,
      theme: MeowTheme.light,
      initialRoute: AppRouter.today,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
