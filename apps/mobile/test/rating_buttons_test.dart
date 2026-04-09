import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/core/memory/widgets/rating_buttons.dart';

void main() {
  group('FsrsRatingButtons', () {
    testWidgets('renders all 4 rating buttons with labels', (tester) async {
      ReviewRating? tappedRating;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FsrsRatingButtons(
            onRate: (r) => tappedRating = r,
          ),
        ),
      ));

      // All 4 labels should be visible
      expect(find.text('不认识'), findsOneWidget);
      expect(find.text('模糊'), findsOneWidget);
      expect(find.text('记得'), findsOneWidget);
      expect(find.text('秒答'), findsOneWidget);
    });

    testWidgets('tapping a button calls onRate with correct rating',
        (tester) async {
      ReviewRating? tappedRating;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FsrsRatingButtons(
            onRate: (r) => tappedRating = r,
          ),
        ),
      ));

      // Tap "记得" (good)
      await tester.tap(find.text('记得'));
      expect(tappedRating, ReviewRating.good);

      // Tap "不认识" (again)
      await tester.tap(find.text('不认识'));
      expect(tappedRating, ReviewRating.again);

      // Tap "秒答" (easy)
      await tester.tap(find.text('秒答'));
      expect(tappedRating, ReviewRating.easy);
    });

    testWidgets('disabled state prevents tap', (tester) async {
      ReviewRating? tappedRating;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FsrsRatingButtons(
            onRate: (r) => tappedRating = r,
            enabled: false,
          ),
        ),
      ));

      await tester.tap(find.text('记得'));
      expect(tappedRating, isNull, reason: 'Disabled buttons should not fire');
    });

    testWidgets('shows preview durations when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FsrsRatingButtons(
            onRate: (_) {},
            previewDurations: const {
              ReviewRating.again: Duration(minutes: 1),
              ReviewRating.hard: Duration(minutes: 10),
              ReviewRating.good: Duration(days: 1),
              ReviewRating.easy: Duration(days: 4),
            },
          ),
        ),
      ));

      expect(find.text('1分钟'), findsOneWidget);
      expect(find.text('10分钟'), findsOneWidget);
      expect(find.text('1天'), findsOneWidget);
      expect(find.text('4天'), findsOneWidget);
    });

    testWidgets('works with 3-button config (no hard)', (tester) async {
      final threeButtonConfigs = defaultRatingConfigs
          .where((c) => c.rating != ReviewRating.hard)
          .toList();
      ReviewRating? tappedRating;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FsrsRatingButtons(
            onRate: (r) => tappedRating = r,
            configs: threeButtonConfigs,
          ),
        ),
      ));

      // Only 3 buttons
      expect(find.text('不认识'), findsOneWidget);
      expect(find.text('模糊'), findsNothing); // hard removed
      expect(find.text('记得'), findsOneWidget);
      expect(find.text('秒答'), findsOneWidget);

      await tester.tap(find.text('秒答'));
      expect(tappedRating, ReviewRating.easy);
    });

    test('defaultRatingConfigs has exactly 4 entries', () {
      expect(defaultRatingConfigs.length, 4);
      expect(defaultRatingConfigs[0].rating, ReviewRating.again);
      expect(defaultRatingConfigs[1].rating, ReviewRating.hard);
      expect(defaultRatingConfigs[2].rating, ReviewRating.good);
      expect(defaultRatingConfigs[3].rating, ReviewRating.easy);
    });

    test('all configs have unique colors', () {
      final colors = defaultRatingConfigs.map((c) => c.color).toSet();
      expect(colors.length, defaultRatingConfigs.length,
          reason: 'Each rating button must have a distinct color');
    });

    test('all configs have icons (色盲友好)', () {
      for (final config in defaultRatingConfigs) {
        expect(config.icon, isNotNull,
            reason:
                '${config.label} must have an icon for accessibility');
      }
    });
  });
}
