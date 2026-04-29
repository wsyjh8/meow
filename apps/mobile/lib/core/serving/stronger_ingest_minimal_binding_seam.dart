/// stronger_ingest_minimal_binding_seam (FROZEN, P3.3.14 — B additive)
///
/// Member 5 of `real_cutover_execution_subset_v1`. Minimal precondition
/// and binding seam for stronger-ingest absorb-readiness. This is the
/// thinnest possible formalization of "stronger ingest has a binding
/// point" — the seam is a pure, no-op, always-succeed contract.
///
/// **This file does NOT write any final fact.** It does NOT call the
/// backend. It does NOT mutate any local state. It only records a
/// binding attempt's formal shape so that a future round can replace
/// the internal no-op with an actual binding implementation without
/// changing callers.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-005: B checkpoint allowed execution direction — Member 5.
/// RF-P3.3.14-015: final fact owner remains backend-authoritative.
/// RF-P3.3.14-016: stronger-ingest may only enter candidate / readiness /
///                 absorbed-judgment discussion layers this round.
library;

/// The precondition shape that a stronger-ingest binding attempt
/// must satisfy. Immutable. No runtime consumer writes facts based
/// on this — it is a structural precondition only.
class StrongerIngestBindingPrecondition {
  /// The word id whose binding shape is being formalized.
  final String wordId;

  /// Whether cloud `review_group` submission has already committed.
  /// Stronger ingest is only discussed after cloud has committed.
  final bool cloudReviewGroupAlreadyCommitted;

  /// Whether the backend fact layer has been consulted as the
  /// authoritative owner (always true this round).
  final bool backendFactLayerConsultedAsAuthoritative;

  const StrongerIngestBindingPrecondition({
    required this.wordId,
    required this.cloudReviewGroupAlreadyCommitted,
    required this.backendFactLayerConsultedAsAuthoritative,
  });
}

/// The result of a minimal binding seam consultation. Always reports
/// `bindingDiscussedOnly = true`, which is the only value this round
/// permits. No final-fact write is performed.
class StrongerIngestBindingResult {
  /// Always true this round. Represents "binding was discussed; no
  /// fact was written".
  final bool bindingDiscussedOnly;

  /// A test-observable tag so the regression suite can verify the
  /// minimal binding was consulted through the seam and not via any
  /// bypass path.
  final String consultationTag;

  /// Always `candidate_discussion` or `readiness_discussion` — never
  /// `absorbed_decision` or `final_owner_shift`.
  final String allowedDiscussionLayer;

  const StrongerIngestBindingResult({
    required this.bindingDiscussedOnly,
    required this.consultationTag,
    required this.allowedDiscussionLayer,
  });
}

abstract final class StrongerIngestMinimalBindingSeam {
  /// The only 2 discussion layers this seam is allowed to report.
  /// Tests assert length == 2.
  static const List<String> kAllowedDiscussionLayers = [
    'candidate_discussion',
    'readiness_discussion',
  ];

  /// The 3 forbidden discussion layers — the seam must NEVER report
  /// any of these as its allowed layer.
  /// Tests assert length == 3.
  static const List<String> kForbiddenDiscussionLayers = [
    'absorbed_decision',
    'final_owner_shift',
    'runtime_truth_shift',
  ];

  /// Consult the minimal binding seam. Always returns a
  /// "binding discussed only" result with `candidate_discussion`.
  /// No I/O, no mutation, no fact write. Pure function.
  static StrongerIngestBindingResult consultMinimalBinding({
    required StrongerIngestBindingPrecondition precondition,
  }) {
    // Precondition guard — the contract requires cloud to have
    // already committed. If it hasn't, the seam still reports a
    // candidate_discussion result but the tag reflects the guard.
    final bool cloudCommitted = precondition.cloudReviewGroupAlreadyCommitted;
    final String tag = cloudCommitted
        ? 'p3_3_14_b_minimal_binding_post_cloud_commit'
        : 'p3_3_14_b_minimal_binding_precondition_unmet_no_write';

    return StrongerIngestBindingResult(
      bindingDiscussedOnly: true,
      consultationTag: tag,
      allowedDiscussionLayer: 'candidate_discussion',
    );
  }

  /// Canonical rule: this seam does not write final facts.
  /// Tests assert this contains 'no_final_fact_write'.
  static const String kCanonicalRule =
      'minimal_binding_seam_performs_no_final_fact_write_and_no_owner_shift_'
      'and_operates_strictly_at_candidate_or_readiness_discussion_layer';

  /// Semantic boundary. Tests assert this contains 'binding_is_discussion_not_write'.
  static const String kSemanticBoundary =
      'binding_is_discussion_not_write_stronger_ingest_cannot_promote_to_final_'
      'owner_this_round';

  /// Linkage to absorb-gate. Tests assert this contains 'absorb_gate'.
  static const String kLinkageToAbsorbGate =
      'minimal_binding_seam_consulted_only_after_cloud_commit_and_only_within_'
      'absorb_gate_qualification_discussion';
}
