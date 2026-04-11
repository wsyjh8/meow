/// shadow_parity_test_strategy_v1 (FROZEN, P3.3.6)
///
/// Defines the 5 fixed parity check types and 3 test categories for
/// shadow/parity evidence gathering. Shadow/parity results can ONLY be
/// written as evidence — never as runtime fact or owner shift completion.
///
/// This file is a CONTRACT ANCHOR — it exposes enums and constants that
/// EXPRESS the frozen test strategy. It does not execute any parity
/// check itself; the actual parity check execution is deferred to
/// Phase 2 shadow mode (not this round).
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.6-016: shadow/parity results can ONLY be written as evidence,
///                NOT as owner shift completion.
///                Allowed results as evidence:
///                  - local candidate looks more reasonable
///                  - local candidate broadly consistent with cloud
///                  - local-routing shadow judgment superior
///                  - local ingest evidence can be cloud-accepted
///                Forbidden:
///                  - owner shift completed
///                  - local already manages ReviewPage
///                  - review_group already exited runtime
///                  - auto-routing already online
///
/// RF-P3.3.6-017: three test categories must be distinguished:
///                  - runtime truth regression
///                  - shadow parity evidence
///                  - marker / contract-only tests
///                Otherwise tests keep miswriting shadow results as
///                runtime fact.
library;

/// The 5 fixed parity check types for shadow evidence gathering.
///
/// These are the exhaustive set of parity checks for P3.3.6. Future
/// rounds may add more, but removing or renaming any of these five is
/// a breaking change to the shadow parity test strategy.
enum ParityCheckType {
  /// Check 1: queue candidate size and emptiness.
  ///
  /// Compares item count between local and cloud candidates.
  /// Semantics: size_match / local_larger / local_smaller / one_empty.
  /// Used for: "do both have work to do" baseline.
  queueCandidateSize,

  /// Check 2: item identity overlap.
  ///
  /// Compares actual card/item IDs between local and cloud candidates.
  /// Semantics: overlap_percentage, missing_in_local, extra_in_local,
  /// identical.
  /// Used for: "are we suggesting review of the same items".
  /// Critical for determining if serving transition is safe.
  itemIdentityOverlap,

  /// Check 3: continuation eligibility judgment.
  ///
  /// Compares active continuation status decision in local vs cloud.
  /// Semantics: both_continue / both_complete / mismatch (one says
  /// continue, one says complete).
  /// Used for: "does continuation block show same content".
  continuationEligibility,

  /// Check 4: submit after-effects evidence completeness.
  ///
  /// After submission (rating input), compares what local vs cloud
  /// record as side-effects.
  /// Semantics: local_evidence_completeness (attempt recorded? rating
  /// recorded? metadata captured?), cloud_confirmation_received.
  /// Used for: "can local completion evidence be fully ingested by cloud".
  submitAfterEffects,

  /// Check 5: fact ingest accept/reject/duplicate behavior consistency.
  ///
  /// Cloud fact layer's response to local evidence: does it consistently
  /// accept/reject/mark-duplicate?
  /// Semantics: acceptance_rate, rejection_rate, duplicate_rate,
  /// reason_consistency.
  /// Used for: "is cloud fact layer ready to receive local evidence as
  /// valid ingest".
  factIngestBehavior,
}

/// The 3 test categories every P3.3.6+ test must belong to.
///
/// This classification prevents the most common silent-drift failure:
/// shadow evidence tests being miswritten as runtime fact tests.
enum ParityTestCategory {
  /// Category 1: runtime truth regression.
  ///
  /// Asserts current runtime behavior has not silently drifted.
  /// Example: "'背单词' still navigates to /study",
  /// "ReviewPage still calls getNextReviewGroup()".
  runtimeTruthRegression,

  /// Category 2: shadow parity evidence.
  ///
  /// Asserts shadow-only evidence would be gathered correctly without
  /// affecting runtime. Results never promoted to runtime fact.
  /// This round: mostly deferred until shadow mode is enabled.
  shadowParityEvidence,

  /// Category 3: marker / contract-only tests.
  ///
  /// Asserts contract anchor constants and enums are stable. No
  /// runtime behavior involved. Most P3.3.x delivery tests (including
  /// this file's associated p336_delivery_test.dart) belong here.
  markerContractOnly,
}

/// Contract anchor constants for the shadow parity test strategy.
abstract final class ShadowParityTestStrategy {
  /// Canonical ordered list of 5 parity check names.
  /// Tests assert this list has exactly 5 entries in this exact order.
  static const List<String> kAllParityCheckNames = [
    'queue_candidate_size',
    'item_identity_overlap',
    'continuation_eligibility',
    'submit_after_effects',
    'fact_ingest_behavior',
  ];

  /// Canonical ordered list of 3 test category names.
  /// Tests assert this list has exactly 3 entries in this exact order.
  static const List<String> kAllTestCategoryNames = [
    'runtime_truth_regression',
    'shadow_parity_evidence',
    'marker_contract_only',
  ];

  /// Forbidden "evidence = runtime fact" claims.
  /// Shadow/parity results must NEVER be written as owner shift completion.
  /// Tests assert none of these appear in any visible copy.
  static const List<String> kForbiddenEvidenceAsFactClaims = [
    'owner shift 已完成',
    'local 已接管 ReviewPage',
    'review_group 已退出运行态',
    '影子模式已正式生效',
    'parity 已通过，现已切换新模式',
    '当前已升级到新 serving 方案',
  ];
}
