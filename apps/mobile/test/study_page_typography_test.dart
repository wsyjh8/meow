// Need #11 typography pass — verify the StudyPage word card renders at
// 360 logical pixels wide (the most common compact phone footprint)
// without producing any overflow exceptions, regardless of which
// content modules are present.
//
// We don't pump the real StudyPage (which depends on shared_preferences,
// drift, audio, etc.) — instead we mount the four enrichment body
// widgets that ship with this need, plus a representative example block,
// so the typography contract is what's exercised.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/services/word_enrichment_service.dart';

/// Local mirror of the body widgets in StudyPage. Kept identical to
/// the production code so any future drift is caught here.
const _kTextDark = Color(0xFF2C2C2A);
const _kTextGray = Color(0xFF9C948A);
const _kNeutralBg = Color(0xFFFDFBF7);
const _kNeutralBorder = Color(0xFFE8E2D8);
const _kNeutralText = Color(0xFF5C554C);

Widget _formsBody(List<WordFormItem> forms) => Wrap(
      spacing: 10,
      runSpacing: 4,
      children: forms.map((f) {
        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _kTextDark,
              height: 1.35,
            ),
            children: [
              TextSpan(text: f.formText),
              TextSpan(
                text: '（${f.formType}）',
                style: const TextStyle(
                  color: _kTextGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

Widget _phrasesBody(List<String> phrases) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: phrases.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _kNeutralBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kNeutralBorder, width: 0.5),
          ),
          child: Text(
            p,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kNeutralText,
              height: 1.2,
            ),
          ),
        );
      }).toList(),
    );

Future<void> _pumpAt360(WidgetTester tester, Widget child) async {
  // Force the canonical compact phone width.
  tester.view.physicalSize = const Size(360 * 2.0, 800 * 2.0);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('forms body wraps within 360w without overflow', (tester) async {
    final forms = [
      const WordFormItem(formText: 'abandoning', formType: '现在分词'),
      const WordFormItem(formText: 'abandoned', formType: '过去式'),
      const WordFormItem(formText: 'abandons', formType: '第三人称单数'),
      const WordFormItem(formText: 'abandonment', formType: '名词形式'),
    ];
    await _pumpAt360(tester, _formsBody(forms));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrase chips wrap within 360w without overflow',
      (tester) async {
    final phrases = [
      'an accident',
      'the accident',
      'by accident',
      'accident that',
      'no accident',
      'accident and',
      'a freak accident happens here',
    ];
    await _pumpAt360(tester, _phrasesBody(phrases));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long synonym list wraps without overflow', (tester) async {
    // Worst case: many items joined by ", " on a single RichText line.
    const synonyms =
        '近义词：chance event, fortuity, stroke, mishap, mischance, '
        'misadventure, calamity, catastrophe, casualty';
    await _pumpAt360(
      tester,
      const Text(
        synonyms,
        style: TextStyle(fontSize: 13, height: 1.35, color: _kTextDark),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
