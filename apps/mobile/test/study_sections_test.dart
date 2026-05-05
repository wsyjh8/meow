// Need #14 v2 — Widget tests for the extracted Section components.
//
// Tests are local-only (no real StudyPage pump) because the page
// depends on shared_preferences / drift / audio / FsrsService /
// SessionStore / ReviewLogService / FSRS bridge. The Section widgets
// are pure UI and can be exercised in isolation here.
//
// Coverage:
//   - WordHeaderSection: word + phonetic visible, speaker callback
//     fires, header height stable across short and very-long inputs,
//     long word + meaning use ellipsis (don't grow the header).
//   - 4 enrichment Sections + Meaning + ExampleSentence: empty input
//     hides the section completely (no title, shrink), non-empty input
//     renders the title and content.
//   - ReviewButtonsSection: each of the 4 buttons fires its rating
//     callback exactly once.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/api/api_client.dart' show Word, WordExample;
import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/core/services/word_enrichment_service.dart';
import 'package:meow_mobile/features/study/widgets/example_sentence_section.dart';
import 'package:meow_mobile/features/study/widgets/meaning_section.dart';
import 'package:meow_mobile/features/study/widgets/review_buttons_section.dart';
import 'package:meow_mobile/features/study/widgets/word_forms_section.dart';
import 'package:meow_mobile/features/study/widgets/word_header_section.dart';
import 'package:meow_mobile/features/study/widgets/word_morphemes_section.dart';
import 'package:meow_mobile/features/study/widgets/word_phrases_section.dart';
import 'package:meow_mobile/features/study/widgets/word_relations_section.dart';

/// `find.textContaining` looks at `Text` widgets only. Forms / relations
/// / morpheme rows render via `RichText` so we walk those manually and
/// inspect their composite plain text.
bool _richTextContains(WidgetTester tester, String needle) {
  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  for (final r in richTexts) {
    if (r.text.toPlainText().contains(needle)) return true;
  }
  return false;
}

Future<void> _pumpInWidth(WidgetTester tester, Widget child,
    {double width = 360}) async {
  tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: child,
        ),
      ),
    ),
  );
}

Word _word({
  String text = 'accident',
  String? phonetic = 'ˈæksɪdənt',
  String meaning = '意外事件',
  String? translation = 'n. 意外事件, 机遇',
}) =>
    Word(
      wordId: 'cet4-test',
      wordText: text,
      meaning: meaning,
      phonetic: phonetic,
      bookId: 'book-001',
      translation: translation,
    );

void main() {
  group('WordHeaderSection', () {
    testWidgets('renders word, phonetic, primary meaning', (tester) async {
      await _pumpInWidth(
        tester,
        WordHeaderSection(
          word: _word(),
          meaningLines: const ['意外事件'],
          isPlayingAudio: false,
          todayCompleted: 1,
          dailyGoal: 20,
          onSpeakerTap: () async {},
        ),
      );
      expect(find.text('accident'), findsOneWidget);
      expect(find.text('ˈæksɪdənt'), findsOneWidget);
      expect(find.text('意外事件'), findsOneWidget);
    });

    testWidgets('speaker tap fires callback exactly once', (tester) async {
      var calls = 0;
      await _pumpInWidth(
        tester,
        WordHeaderSection(
          word: _word(),
          meaningLines: const ['意外事件'],
          isPlayingAudio: false,
          todayCompleted: 0,
          dailyGoal: 20,
          onSpeakerTap: () async => calls++,
        ),
      );
      await tester.tap(find.text('发音'));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('renders identical height for short vs very long input',
        (tester) async {
      // Short
      await _pumpInWidth(
        tester,
        WordHeaderSection(
          word: _word(text: 'cat', phonetic: 'kæt', meaning: '猫'),
          meaningLines: const ['猫'],
          isPlayingAudio: false,
          todayCompleted: 0,
          dailyGoal: 20,
          onSpeakerTap: () async {},
        ),
      );
      final shortHeight =
          tester.getSize(find.byType(WordHeaderSection)).height;

      // Very long word (45 chars) and very long meaning.
      await _pumpInWidth(
        tester,
        WordHeaderSection(
          word: _word(
            text: 'pneumonoultramicroscopicsilicovolcanoconiosis',
            phonetic: 'a' * 60,
            meaning: '一个被故意写得非常长的中文释义' * 3,
          ),
          meaningLines: List.filled(3, '一个被故意写得非常长的中文释义'),
          isPlayingAudio: false,
          todayCompleted: 0,
          dailyGoal: 20,
          onSpeakerTap: () async {},
        ),
      );
      final longHeight =
          tester.getSize(find.byType(WordHeaderSection)).height;

      // Both heights must be identical (the SizedBox(156) wrapper
      // strictly fixes the height regardless of content). Capping at
      // 170px keeps a small safety margin so a future padding tweak
      // doesn't blow up the test on 1px diffs.
      expect(shortHeight, equals(longHeight));
      expect(longHeight, lessThanOrEqualTo(170));
    });
  });

  group('MeaningSection', () {
    testWidgets('empty list → not rendered', (tester) async {
      await _pumpInWidth(tester, const MeaningSection(lines: []));
      expect(find.text('释义'), findsNothing);
    });

    testWidgets('non-empty → title + lines visible', (tester) async {
      await _pumpInWidth(
        tester,
        const MeaningSection(lines: ['n. 意外事件', '[经] 意外事故']),
      );
      expect(find.text('释义'), findsOneWidget);
      expect(find.text('n. 意外事件'), findsOneWidget);
      expect(find.text('[经] 意外事故'), findsOneWidget);
    });
  });

  group('ExampleSentenceSection', () {
    testWidgets('empty → not rendered', (tester) async {
      await _pumpInWidth(tester, const ExampleSentenceSection(examples: []));
      expect(find.text('例句'), findsNothing);
    });

    testWidgets('renders en + cn for each example (cap 2)', (tester) async {
      const examples = [
        WordExample(sense: 'n.', en: 'A car accident.', cn: '车祸。'),
        WordExample(sense: 'n.', en: 'The traffic accident.', cn: '交通事故。'),
      ];
      await _pumpInWidth(
        tester,
        const ExampleSentenceSection(examples: examples),
      );
      expect(find.text('例句'), findsOneWidget);
      expect(find.text('A car accident.'), findsOneWidget);
      expect(find.text('车祸。'), findsOneWidget);
      expect(find.text('The traffic accident.'), findsOneWidget);
      expect(find.text('交通事故。'), findsOneWidget);
    });
  });

  group('WordFormsSection', () {
    testWidgets('empty → not rendered', (tester) async {
      await _pumpInWidth(tester, const WordFormsSection(forms: []));
      expect(find.text('其他形式'), findsNothing);
    });

    testWidgets('renders form text + Chinese type label', (tester) async {
      await _pumpInWidth(
        tester,
        WordFormsSection(forms: [
          const WordFormItem(formText: 'accidents', formType: 'plural'),
        ]),
      );
      expect(find.text('其他形式'), findsOneWidget);
      // form text + parenthesised label live in a single RichText, so
      // we walk RichText widgets manually.
      expect(_richTextContains(tester, 'accidents'), isTrue);
      expect(_richTextContains(tester, '复数'), isTrue);
    });
  });

  group('WordRelationsSection', () {
    testWidgets('both empty → not rendered', (tester) async {
      await _pumpInWidth(
        tester,
        const WordRelationsSection(synonyms: [], antonyms: []),
      );
      expect(find.text('近反义词'), findsNothing);
    });

    testWidgets('only synonyms → only "近义词：" row appears', (tester) async {
      // Note: the section title "近反义词" itself produces a RichText
      // whose plain text contains the substring "反义词", so we look
      // for the colon-prefixed labels which are unique to the row
      // bodies.
      await _pumpInWidth(
        tester,
        const WordRelationsSection(
          synonyms: ['mishap', 'fortuity'],
          antonyms: [],
        ),
      );
      expect(find.text('近反义词'), findsOneWidget);
      expect(_richTextContains(tester, '近义词：'), isTrue);
      expect(_richTextContains(tester, '反义词：'), isFalse);
    });

    testWidgets('only antonyms → only "反义词：" row appears', (tester) async {
      await _pumpInWidth(
        tester,
        const WordRelationsSection(
          synonyms: [],
          antonyms: ['plan'],
        ),
      );
      expect(find.text('近反义词'), findsOneWidget);
      expect(_richTextContains(tester, '近义词：'), isFalse);
      expect(_richTextContains(tester, '反义词：'), isTrue);
    });
  });

  group('WordPhrasesSection', () {
    testWidgets('empty → not rendered', (tester) async {
      await _pumpInWidth(tester, const WordPhrasesSection(phrases: []));
      expect(find.text('常见词组'), findsNothing);
    });

    testWidgets('non-empty → title + chip text visible', (tester) async {
      await _pumpInWidth(
        tester,
        const WordPhrasesSection(phrases: ['an accident', 'by accident']),
      );
      expect(find.text('常见词组'), findsOneWidget);
      expect(find.text('an accident'), findsOneWidget);
      expect(find.text('by accident'), findsOneWidget);
    });
  });

  group('WordMorphemesSection', () {
    testWidgets('empty → not rendered', (tester) async {
      await _pumpInWidth(tester, const WordMorphemesSection(morphemes: []));
      expect(find.text('词根词缀参考'), findsNothing);
    });

    testWidgets('non-empty → title + morpheme rows visible', (tester) async {
      const matches = [
        MorphemeMatch(
          morpheme: 'ab-',
          normalizedMorpheme: 'ab',
          morphemeType: 'prefix',
          position: 'prefix',
          meanings: ['away from'],
          confidence: 0.85,
        ),
        MorphemeMatch(
          morpheme: '-don',
          normalizedMorpheme: 'don',
          morphemeType: 'suffix',
          position: 'suffix',
          meanings: ['give'],
          confidence: 0.85,
        ),
      ];
      await _pumpInWidth(
        tester,
        const WordMorphemesSection(morphemes: matches),
      );
      expect(find.text('词根词缀参考'), findsOneWidget);
      expect(_richTextContains(tester, 'ab-'), isTrue);
      expect(_richTextContains(tester, '-don'), isTrue);
      expect(_richTextContains(tester, 'away from'), isTrue);
    });
  });

  group('ReviewButtonsSection', () {
    testWidgets('all 4 buttons render', (tester) async {
      await _pumpInWidth(
        tester,
        ReviewButtonsSection(
          enabled: true,
          previewDurations: null,
          onRate: (_) {},
        ),
      );
      expect(find.text('熟悉'), findsOneWidget);
      expect(find.text('认识'), findsOneWidget);
      expect(find.text('模糊'), findsOneWidget);
      expect(find.text('不认识'), findsOneWidget);
    });

    testWidgets('each button fires its specific rating callback once',
        (tester) async {
      final fired = <ReviewRating>[];
      await _pumpInWidth(
        tester,
        ReviewButtonsSection(
          enabled: true,
          previewDurations: null,
          onRate: fired.add,
        ),
      );

      await tester.tap(find.text('熟悉'));
      await tester.pump();
      await tester.tap(find.text('认识'));
      await tester.pump();
      await tester.tap(find.text('模糊'));
      await tester.pump();
      await tester.tap(find.text('不认识'));
      await tester.pump();

      expect(
        fired,
        [
          ReviewRating.easy,
          ReviewRating.good,
          ReviewRating.hard,
          ReviewRating.again,
        ],
      );
    });

    testWidgets('disabled state suppresses taps', (tester) async {
      var calls = 0;
      await _pumpInWidth(
        tester,
        ReviewButtonsSection(
          enabled: false,
          previewDurations: null,
          onRate: (_) => calls++,
        ),
      );
      await tester.tap(find.text('熟悉'));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('preview disclaimer shown only when previewDurations != null',
        (tester) async {
      await _pumpInWidth(
        tester,
        ReviewButtonsSection(
          enabled: true,
          previewDurations: null,
          onRate: (_) {},
        ),
      );
      expect(find.text('预计间隔（仅供参考）'), findsNothing);

      await _pumpInWidth(
        tester,
        ReviewButtonsSection(
          enabled: true,
          previewDurations: const {ReviewRating.good: Duration(minutes: 1)},
          onRate: (_) {},
        ),
      );
      expect(find.text('预计间隔（仅供参考）'), findsOneWidget);
    });
  });
}
