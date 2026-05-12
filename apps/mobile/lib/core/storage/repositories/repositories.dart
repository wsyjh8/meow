/// Public exports for the user-scoped storage repositories
/// (需求 23 Phase C PR-C-β / plan-023-C-v2 §4.4).
///
/// Every repository in this directory takes `AppDatabase db` and
/// `String userId` at construction and constrains all of its queries
/// to that user via `WHERE user_id = ?`. Construct one per
/// (database, user) pair — typically in main.dart from the bound user
/// after AuthBootstrap completes.
library;

export 'card_state_repository.dart';
export 'daily_checkin_repository.dart';
export 'review_log_repository.dart';
export 'review_record_repository.dart';
export 'session_repository.dart';
