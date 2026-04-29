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

  const WordExample({
    required this.sense,
    required this.en,
    required this.cn,
  });
}
