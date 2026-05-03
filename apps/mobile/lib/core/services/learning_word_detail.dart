import 'package:flutter/foundation.dart' show immutable;

import '../api/api_client.dart' show Word;
import 'word_enrichment_service.dart' show WordEnrichment;

/// Aggregated payload of one word's full study-card data: the [Word]
/// itself (already with examples attached by [StudyService.getNextWord])
/// plus its [WordEnrichment] (forms / relations / phrases / morphemes).
///
/// Built by [WordDetailRepository.attachEnrichment]. Lives only in
/// memory — never serialised, never persisted, never crosses isolates.
@immutable
class LearningWordDetail {
  final Word word;
  final WordEnrichment enrichment;

  const LearningWordDetail({required this.word, required this.enrichment});

  String get wordId => word.wordId;
  String get wordText => word.wordText;
}
