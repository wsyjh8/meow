// Need #11 typography pass (now Need #14 v2: imports the real Section
// widgets instead of mirrored inline copies). Verify the study card
// renders at 360 logical pixels wide — the most common compact phone
// footprint — without producing any RenderFlex / Wrap overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/services/word_enrichment_service.dart';
import 'package:meow_mobile/features/study/widgets/word_forms_section.dart';
import 'package:meow_mobile/features/study/widgets/word_phrases_section.dart';
import 'package:meow_mobile/features/study/widgets/word_relations_section.dart';

Future<void> _pumpAt360(WidgetTester tester, Widget child) async {
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
  testWidgets('WordFormsSection wraps within 360w without overflow',
      (tester) async {
    final forms = [
      const WordFormItem(formText: 'abandoning', formType: 'present_participle'),
      const WordFormItem(formText: 'abandoned', formType: 'past'),
      const WordFormItem(formText: 'abandons', formType: 'third_person_singular'),
      const WordFormItem(formText: 'abandonment', formType: 'plural'),
    ];
    await _pumpAt360(tester, WordFormsSection(forms: forms));
    expect(tester.takeException(), isNull);
  });

  testWidgets('WordPhrasesSection chips wrap within 360w without overflow',
      (tester) async {
    const phrases = [
      'an accident',
      'the accident',
      'by accident',
      'accident that',
      'no accident',
      'accident and',
      'a freak accident happens here',
    ];
    await _pumpAt360(tester, const WordPhrasesSection(phrases: phrases));
    expect(tester.takeException(), isNull);
  });

  testWidgets('WordRelationsSection long synonyms list does not overflow',
      (tester) async {
    const synonyms = [
      'chance event',
      'fortuity',
      'stroke',
      'mishap',
      'mischance',
      'misadventure',
      'calamity',
      'catastrophe',
      'casualty',
    ];
    await _pumpAt360(
      tester,
      const WordRelationsSection(synonyms: synonyms, antonyms: []),
    );
    expect(tester.takeException(), isNull);
  });
}
