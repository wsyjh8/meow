/// DTO for card state data exposed to UI and service consumers.
///
/// This is a pure data class with no FSRS library dependencies.
/// FsrsService converts between drift rows and this DTO internally.
class CardStateData {
  final int id;
  final String wordId;
  final double? stability;
  final double? difficulty;
  final DateTime dueUtc;
  final DateTime? lastReviewUtc;

  /// 1=Learning, 2=Review, 3=Relearning
  final int state;
  final int? step;
  final int reps;
  final int lapses;
  final DateTime createdAtUtc;

  const CardStateData({
    required this.id,
    required this.wordId,
    this.stability,
    this.difficulty,
    required this.dueUtc,
    this.lastReviewUtc,
    required this.state,
    this.step,
    required this.reps,
    required this.lapses,
    required this.createdAtUtc,
  });

  /// Whether this card has never been reviewed (brand new).
  bool get isNew => lastReviewUtc == null;

  /// Human-readable state label (for debugging).
  String get stateLabel {
    switch (state) {
      case 1:
        return 'Learning';
      case 2:
        return 'Review';
      case 3:
        return 'Relearning';
      default:
        return 'Unknown($state)';
    }
  }
}
