import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// P3.1 Phase 1 — Local progress persistence repository.
///
/// Stores user progress data on-device using SharedPreferences JSON encoding.
/// This is the device-side runtime truth for user progress.
///
/// IMPORTANT:
/// - This is NOT a replacement for backend business rules.
/// - This is device-side progress persistence for offline / restart survival.
/// - Phase 2 (snapshot export) will read from this layer.
/// - Phase 3 (cloud upload) will serialize from this layer.
///
/// NOT done in this phase:
/// - snapshot export
/// - cloud upload
/// - restore
/// - sync
class LocalProgressRepository {
  final SharedPreferences _prefs;

  LocalProgressRepository(this._prefs);

  // ==================== Keys ====================
  static const _keyWordRecords = 'progress_word_records';
  static const _keyWordbookProgress = 'progress_wordbook_progress';
  static const _keyDailyCheckins = 'progress_daily_checkins';
  static const _keyCustomWordbooks = 'progress_custom_wordbooks';
  static const _keyVocabularyNotebook = 'progress_vocabulary_notebook';

  // ==================== Word Records ====================

  /// Get all word learning records.
  List<Map<String, dynamic>> getWordRecords() => _getJsonList(_keyWordRecords);

  /// Save a word record (append).
  Future<bool> addWordRecord(Map<String, dynamic> record) async {
    final records = getWordRecords();
    records.add(record);
    return _setJsonList(_keyWordRecords, records);
  }

  /// Replace all word records (for batch operations).
  Future<bool> setWordRecords(List<Map<String, dynamic>> records) =>
      _setJsonList(_keyWordRecords, records);

  // ==================== Wordbook Progress ====================

  /// Get wordbook progress state.
  Map<String, dynamic>? getWordbookProgress() => _getJsonMap(_keyWordbookProgress);

  /// Save wordbook progress.
  Future<bool> setWordbookProgress(Map<String, dynamic> progress) =>
      _setJsonMap(_keyWordbookProgress, progress);

  // ==================== Daily Check-ins ====================

  /// Get all daily check-in records.
  List<Map<String, dynamic>> getDailyCheckins() => _getJsonList(_keyDailyCheckins);

  /// Add a daily check-in record.
  Future<bool> addDailyCheckin(Map<String, dynamic> record) async {
    final checkins = getDailyCheckins();
    checkins.add(record);
    return _setJsonList(_keyDailyCheckins, checkins);
  }

  /// Replace all check-in records.
  Future<bool> setDailyCheckins(List<Map<String, dynamic>> records) =>
      _setJsonList(_keyDailyCheckins, records);

  // ==================== Custom Wordbooks ====================

  /// Get custom wordbook list.
  List<Map<String, dynamic>> getCustomWordbooks() => _getJsonList(_keyCustomWordbooks);

  /// Save custom wordbooks.
  Future<bool> setCustomWordbooks(List<Map<String, dynamic>> books) =>
      _setJsonList(_keyCustomWordbooks, books);

  // ==================== Vocabulary Notebook ====================

  /// Get vocabulary notebook entries.
  List<Map<String, dynamic>> getVocabularyNotebook() => _getJsonList(_keyVocabularyNotebook);

  /// Add a vocabulary notebook entry.
  Future<bool> addVocabularyEntry(Map<String, dynamic> entry) async {
    final entries = getVocabularyNotebook();
    entries.add(entry);
    return _setJsonList(_keyVocabularyNotebook, entries);
  }

  /// Replace all notebook entries.
  Future<bool> setVocabularyNotebook(List<Map<String, dynamic>> entries) =>
      _setJsonList(_keyVocabularyNotebook, entries);

  // ==================== Utility ====================

  /// Check if local progress has any data.
  bool get hasAnyData =>
      getWordRecords().isNotEmpty ||
      getWordbookProgress() != null ||
      getDailyCheckins().isNotEmpty ||
      getCustomWordbooks().isNotEmpty ||
      getVocabularyNotebook().isNotEmpty;

  /// Clear all local progress data (debug / testing only).
  Future<void> clearAll() async {
    await _prefs.remove(_keyWordRecords);
    await _prefs.remove(_keyWordbookProgress);
    await _prefs.remove(_keyDailyCheckins);
    await _prefs.remove(_keyCustomWordbooks);
    await _prefs.remove(_keyVocabularyNotebook);
  }

  // ==================== Internal JSON helpers ====================

  List<Map<String, dynamic>> _getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> _setJsonList(String key, List<Map<String, dynamic>> list) =>
      _prefs.setString(key, json.encode(list));

  Map<String, dynamic>? _getJsonMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _setJsonMap(String key, Map<String, dynamic> map) =>
      _prefs.setString(key, json.encode(map));
}
