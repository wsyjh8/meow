# R4_P3_3_Session_Entry_Draft_v0.1

- **Owner:** Room 4
- **Project:** 背单词喵喵 App
- **Type:** execution draft — session entry
- **Status:** Phase A draft
- **Date:** 2026-04-09
- **Basis:** R1_to_R4_P3_3_Execution_Handoff_v0.1.md

---

## 1. Home → StudyPage Entry

### Frozen (this round)

- SpecHomePage gains a dedicated "背单词" labeled entry (`_buildStudyEntry()`).
- Tapping it calls: `Navigator.pushNamed(context, '/study')`
- `AppRouter` already maps `/study → StudyPage`. No router change required.
- The existing `_buildMainCTA()` (hero card "继续学习", also navigates to `/study`) is **retained** — it shows task progress data and is not removed.

### NOT decided by Room 4 (pending)

| Decision | Why Pending |
|----------|-------------|
| Whether StudyPage auto-starts any session type upon entry | Room 2 / Room 3 / Room 1 decision; not in frozen scope |
| Whether a new-word session, review session, or mixed session is created | Session launch mode not frozen |
| Whether `SessionBuilder.buildTodaySession()` is called at StudyPage init | Planner owner not yet decided |
| Whether automatic readiness-based routing occurs | CTA switching pending Room 3 + Room 2 |

### Current StudyPage behavior preserved (unchanged)

`StudyPage.initState()` currently calls:
1. `_studyService.syncPendingAttempts()` — syncs pending local records
2. `_loadNextWord()` — fetches next word via StudyService (API-driven)

Phase B does **NOT** change this session acquisition logic. Phase B only:
- Adds `FsrsService` instantiation
- Replaces the 2-button Row with `FsrsRatingButtons`

---

## 2. ReviewPage Entry

### Frozen (this round)

- ReviewPage entry path is **unchanged**: `SpecHomePage._buildQuickReview()` → `Navigator.pushNamed(context, '/review')`
- ReviewPage continues to call `ApiClient.getNextReviewGroup()` as its primary entry mechanism
- `review_group` remains the **cloud truth layer** for ReviewPage's word queue

### Bridge-first rule

- Local FSRS (`FsrsService.rateCard()`) is a **side-effect bridge** applied AFTER the cloud submit in ReviewPage
- Local FSRS does **NOT** replace or precede `review_group` as the source of truth for ReviewPage content
- ReviewPage does **NOT** query `FsrsService.listDueCards()` or `SessionBuilder` for its word queue

---

## 3. FSRS Coexistence Model

### StudyPage (local-first path)

```
User enters StudyPage
  │
  ├─ initState: FsrsService(db: AppDatabase()) initialized
  ├─ initState: _studyService.syncPendingAttempts()  [existing]
  ├─ initState: _loadNextWord()  [existing — API driven]
  │
  └─ User taps rating button
       │
       ├─ FsrsService.initCardForWord(wordId)   → card_states (drift AppDatabase)
       ├─ FsrsService.rateCard(wordId, rating)  → card_states + review_logs (drift AppDatabase)
       └─ StudyService.submitStudyAttempt(binary) → word_records (LocalDatabase) + async cloud sync
```

The FSRS write and the StudyService write are **independent** — they use different tables and different database abstractions. They do not share a transaction.

### ReviewPage (cloud-first path, FSRS as bridge)

```
User enters ReviewPage
  │
  ├─ initState: FsrsService(db: AppDatabase()) initialized
  ├─ initState: _loadReviewGroup()  [existing — cloud driven]
  │
  └─ User taps rating button
       │
       ├─ ApiClient.submitReviewAttempt(binary, idempotencyKey)  [cloud — PRIMARY, must succeed]
       ├─ try: FsrsService.rateCard(wordId, rating)  [local bridge — best-effort]
       │    └─ catch(_) { } — silent failure if card_states row missing
       └─ Existing group completion / settlement handling
```

### What FSRS coexistence does NOT mean

- Local FSRS does **not** replace `review_group` as the readiness signal for ReviewPage
- `FsrsService.listDueCards()` is **not** surfaced to SpecHomePage or used to compute today's review count
- FSRS data in `card_states` does **not** affect cloud `review_group` continuation or settlement

---

## 4. Decisions That Remain Pending

| Decision | Owner | Why Pending |
|----------|-------|-------------|
| StudyPage session auto-start type | Room 2 / Room 3 / Room 1 | Not in this round's frozen scope |
| Whether StudyPage calls `SessionBuilder` | Room 2 | Bridge-first only — not decided |
| HomeEntry review readiness CTA switching | Room 3 / Room 2 | Out of scope this round |
| Full review planner owner (FSRS vs cloud) | Room 1 | Explicitly deferred |
| StudyPage + ReviewPage convergence to single page | Room 2 / Room 5 | Deferred |
| `initCardForWord` called in ReviewPage | Room 2 | Bridge failure is silent this round; full card init for review items deferred |
