import 'package:flutter/material.dart';
import '../../features/today/today_page.dart';
import '../../features/study/study_page.dart';
import '../../features/session/session_page.dart';
import '../../spec/pages/spec_review_page.dart';
import '../../features/check_in/check_in_page.dart';
import '../../features/settlement/settlement_page.dart';
import '../../features/meow_home/meow_home_page.dart';
import '../../features/inventory/inventory_page.dart';
import '../../features/customize/customize_page.dart';
import '../../features/settings/settings_page.dart';
import '../../spec/pages/books_page.dart';

class AppRouter {
  static const String today = '/';
  static const String study = '/study';
  static const String review = '/review';
  static const String session = '/session';
  static const String checkIn = '/check-in';
  static const String settlement = '/settlement';
  static const String meowHome = '/meow-home';
  static const String inventory = '/inventory';
  static const String customize = '/customize';
  static const String settings = '/settings';
  static const String books = '/books';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case today:
        return _buildPage(const TodayPage(), settings);
      case study:
        return _buildPage(const StudyPage(), settings);
      case review:
        return _buildPage(const SpecReviewPage(), settings);
      case session:
        return _buildPage(const SessionPage(), settings);
      case checkIn:
        return _buildPage(const CheckInPage(), settings);
      case settlement:
        return _buildPage(const SettlementPage(), settings);
      case meowHome:
        return _buildPage(const MeowHomePage(), settings);
      case inventory:
        return _buildPage(const InventoryPage(), settings);
      case customize:
        return _buildPage(const CustomizePage(), settings);
      case AppRouter.settings:
        return _buildPage(const SettingsPage(), settings);
      case books:
        return _buildPage(const BooksPage(), settings);
      default:
        return _buildPage(
          Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static Route<dynamic> _buildPage(Widget page, RouteSettings settings) {
    // Soft page transition — fade + slight slide up
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
