import '../review/review_group_compatibility.dart';
import '../serving/local_serving_candidate_contract.dart';

/// Internal data class expressing the 8 P3.3.6 field group semantics.
///
/// IMPORTANT: This is NOT an API DTO, NOT a DB schema, NOT a contract
/// commitment. The canonical contract lives in
/// `lib/core/serving/local_serving_candidate_contract.dart` (from P3.3.6).
/// This file is an INTERNAL implementation used only by shadow code and
/// tests. Future rounds may rewrite the shape freely without breaking
/// any external consumer.
///
/// shadow_only: this class is never consumed by runtime. `shadowOnly`
/// is hard-set to `true` by all builders in `LocalServingShadowRunner`.
///
/// local_serving_shadow_run_v1 (P3.3.7 Phase 2 Limited Execution)
///
/// Field mapping to P3.3.6 contract anchor:
///   Field 1 — source_type                → `sourceType`
///   Field 2 — source_id                  → `sourceId`
///   Field 3 — owner_layer                → `ownerLayer`
///   Field 4 — shadow_only                → `shadowOnly`
///   Field 5 — candidate_reason           → `candidateReason`
///   Field 6 — generated_at               → `generatedAtUtc`
///   Field 7 — item_count                 → `itemCount`
///   Field 8 — serving_eligibility_state  → `servingEligibilityState`
class LocalServingCandidate {
  /// Field 1: source_type.
  final LocalServingSourceType sourceType;

  /// Field 2: source_id — unique ID within origin system.
  final String sourceId;

  /// Field 3: owner_layer.
  final PlannerOwnerLayer ownerLayer;

  /// Field 4: shadow_only — always true for P3.3.7 shadow candidates.
  /// Any `false` here would constitute a runtime owner shift and is
  /// forbidden this round.
  final bool shadowOnly;

  /// Field 5: candidate_reason.
  final CandidateReason candidateReason;

  /// Field 6: generated_at — timestamp of candidate assembly.
  final DateTime generatedAtUtc;

  /// Field 7: item_count — number of items in this candidate.
  final int itemCount;

  /// Field 8: serving_eligibility_state.
  /// MUST be `shadowOnly` this round. NEVER `runtimeActive`.
  final ServingEligibilityState servingEligibilityState;

  /// Ordered list of word_ids that make up the candidate queue.
  /// Derived from the input (e.g., CardStateData list for due queue).
  /// Not counted as one of the 8 semantic fields — it is the concrete
  /// item payload that `itemCount` summarizes.
  final List<String> wordIds;

  const LocalServingCandidate({
    required this.sourceType,
    required this.sourceId,
    required this.ownerLayer,
    required this.shadowOnly,
    required this.candidateReason,
    required this.generatedAtUtc,
    required this.itemCount,
    required this.servingEligibilityState,
    required this.wordIds,
  });

  /// Assertion helper: this candidate must be shadow-only this round.
  /// Tests use this to catch any accidental `shadowOnly = false`.
  bool get isShadowOnly => shadowOnly;
}
