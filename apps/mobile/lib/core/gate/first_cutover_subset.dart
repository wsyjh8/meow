/// first_cutover_subset_v1 (FROZEN, P3.3.9)
///
/// Contract anchor listing which subset is allowed to enter the first
/// very narrow cutover. Only ONE subset is allowed this round.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-001: only ReviewPage internal serving seam's very narrow
///                subset is allowed for first cutover; forbidden:
///                home page runtime switch, active continuation rewrite,
///                review_group exit, final fact owner shift, DB/API
///                baseline uplift.
///
/// RF-P3.3.9-002: first cutover must cut an actual runtime seam, not
///                just helper/copy/state contract changes alone; serving
///                seam is the minimum true cut, not homepage entry.
///
/// RF-P3.3.9-003: first cutover should NOT cut stronger ingest/final-
///                fact path first, but rather very narrow serving seam
///                subset while keeping final fact owner unchanged.
///
/// RF-P3.3.9-004: only allowed runtime-truth switch candidate is
///                ReviewPage internal "where current review items come
///                from" very narrow serving seam.
library;

abstract final class FirstCutoverSubset {
  /// The ONLY allowed first-cutover subset this round.
  /// Tests assert this exact string.
  static const String kOnlyAllowedSubset =
      'reviewpage_non_continuation_serving_subset';

  /// Allowed layers within the subset (RF-P3.3.9-001/002).
  /// Tests assert all 5 canonical layers are present.
  static const List<String> kAllowedLayers = [
    'queue_source_selection_runtime_seam',
    'local_serving_candidate_item_stream_provision',
    'retained_anchor_and_rollback_hooks',
    'observability_floor',
    'source_neutral_helper_summary_empty_state_continuation_copy_neutralization',
  ];

  /// Forbidden subsets — must NOT be part of any first cutover this round.
  /// Tests assert all canonical forbidden subsets are present.
  static const List<String> kForbiddenSubsets = [
    'home_page_runtime_switch',
    'active_continuation_rewrite',
    'review_group_exit',
    'final_fact_owner_shift',
    'db_api_baseline_uplift',
    'full_reviewpage_current_truth_switch',
    'cleanup_bundling',
    'auto_routing_runtime',
  ];

  /// Canonical constraint: first cutover is "runtime seam" not "copy only".
  /// RF-P3.3.9-002 in canonical string form.
  static const String kCanonicalRule =
      'first_cutover_must_cut_actual_runtime_seam_not_just_copy';

  /// Tests assert this is the ONLY subset and that it does not appear
  /// in the forbidden list.
  static bool get isAllowedSubsetNotInForbiddenList =>
      !kForbiddenSubsets.contains(kOnlyAllowedSubset);
}
