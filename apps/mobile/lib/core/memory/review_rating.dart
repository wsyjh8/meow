/// Project-level review rating enum.
///
/// This enum is the ONLY rating type that UI code should use.
/// The fsrs library's Rating type does NOT leak past FsrsService.
///
/// Mapping to user-facing text:
///   again → "不认识"
///   hard  → "模糊"
///   good  → "想了一下才记起"
///   easy  → "秒答"
enum ReviewRating {
  again, // fsrs Rating.again (1)
  hard, // fsrs Rating.hard  (2)
  good, // fsrs Rating.good  (3)
  easy, // fsrs Rating.easy  (4)
}
