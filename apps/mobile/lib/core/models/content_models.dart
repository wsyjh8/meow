/// App-side local content models.
///
/// These are NOT cloud API contracts — they represent data sourced from
/// bundled assets (word_entries / example_sentences drift tables).
/// Do NOT conflate with cloud API response DTOs in api_client.dart.

/// A single AI-generated example sentence for a word.
/// Sourced from [example_sentences] drift table (populated by [WordbookLoader]).
class WordExample {
  final String sense; // Sense/义项 label, e.g. 'v. 放弃；抛弃'
  final String en;    // English sentence, may contain [bracket] highlights
  final String cn;    // Chinese translation, may contain [bracket] highlights

  /// v0.3.0 pilot — content-addressable example ID, used to query
  /// `/api/v1/examples/:stable_id/audio`.
  ///
  /// Nullable because:
  ///   - Existing bundled assets (assets/words/*.json) don't carry stable_id yet
  ///   - Drift `example_sentences` table doesn't have this column yet
  ///   - Will be populated when (a) Codex pipeline syncs stable_id into mobile
  ///     assets, or (b) drift v9 migration adds the column + recompute on import
  ///
  /// When null → UI must NOT show audio play button (no way to fetch audio).
  /// See `apps/mobile/lib/core/audio/example_audio_service.dart`.
  final String? stableId;

  const WordExample({
    required this.sense,
    required this.en,
    required this.cn,
    this.stableId,
  });
}
