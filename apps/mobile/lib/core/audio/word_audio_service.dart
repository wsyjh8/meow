import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import 'audio_cache_repository.dart';

/// 单词发音服务（v0.3.0 P2.2）。
///
/// 通过 canonical [wordId]（lowercase normalized form, e.g. 'abandon'）拿单词
/// 音频。结构与 [ExampleAudioService] 完全对称，只是 API endpoint 是
/// `/api/v1/words/:word_id/audio`。
///
/// 替代关系：本服务 v0.3.0 形态；旧 `PronunciationService` 走的是 v0.2.x
/// `/api/v1/pronunciation/{word}.wav` 路径。在 Codex pipeline 完成单词音频
/// 全量生成之前，二者并存：study_page 先调本服务，404 时 fallback 到
/// PronunciationService（见 P2.2.C）。
///
/// 共享缓存（[AudioCacheRepository]）：单词和例句的 audio_id 都是全局唯一
/// （含 target_kind 进 hash），因此共用同一张 audio_file_cache 表 + 同一
/// 个文件目录。LRU / orphan eviction 跨类型生效。
///
/// 失败处理（DB §11）：API 404 / 网络失败 → [AudioFetchException]，UI 灰
/// 按钮，**绝不**调用系统 TTS 兜底。
class WordAudioService {
  WordAudioService({AudioCacheRepository? cache})
      : _cache = cache ?? AudioCacheRepository();

  final AudioCacheRepository _cache;
  final AudioPlayer _player = AudioPlayer();

  /// 模拟器内通过 10.0.2.2 访问宿主机上的 API（端口 3000）。
  /// 真机调试时改为局域网 IP。
  static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';

  /// 默认 voice（与 ExampleAudioService 一致）。P2.2 单词的 4 voice 扩展
  /// 后，本服务支持 [voice] 参数；UI 选择 voice 的产品决策见 PD-T-012。
  static const String _defaultVoice = 'af_bella';

  /// 正在下载中的 audio_id 集合。
  final Set<String> _downloading = {};

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  // ── 播放 ─────────────────────────────────────────────────────────────────

  /// 播放 [wordId] 单词音频，使用 [voice]（默认 af_bella）。
  Future<void> play(String wordId, {String voice = _defaultVoice}) async {
    try {
      final meta = await _fetchMeta(wordId, voice);
      final cached = await _cache.findByAudioId(meta.audioId);

      if (cached != null && cached.cachedChecksum == meta.checksumSha256) {
        final file = File(cached.localPath);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(cached.localPath));
          await _cache.touchPlayedAt(meta.audioId);
          return;
        }
        await _cache.deleteEntry(meta.audioId);
      }

      await _player.play(UrlSource(meta.url));
      _backgroundDownload(meta);
    } catch (e) {
      await _player.stop().catchError((_) {});
      rethrow;
    }
  }

  // ── 预加载 ───────────────────────────────────────────────────────────────

  /// 进词书时预下载（DB §7.4.2）：调用方传将要学习的 wordId 列表，并发预拉。
  void prefetch(List<String> wordIds, {String voice = _defaultVoice}) {
    for (final id in wordIds) {
      if (id.isEmpty) continue;
      _prefetchOne(id, voice);
    }
  }

  Future<void> _prefetchOne(String wordId, String voice) async {
    try {
      final meta = await _fetchMeta(wordId, voice);
      if (_downloading.contains(meta.audioId)) return;
      final existing = await _cache.findByAudioId(meta.audioId);
      if (existing != null && existing.cachedChecksum == meta.checksumSha256) {
        if (await File(existing.localPath).exists()) return;
      }
      await _doDownload(meta);
    } catch (_) {/* silently — play will retry */}
  }

  // ── 内部 ─────────────────────────────────────────────────────────────────

  Future<AudioMeta> _fetchMeta(String wordId, String voice) async {
    // word_id 可能含连字符 / 撇号，做 path 编码安全。
    final encoded = Uri.encodeComponent(wordId);
    final uri = Uri.parse(
      '$_baseUrl/words/$encoded/audio?voice=$voice&format=mp3',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw AudioFetchException(
        'Failed to fetch word audio meta: '
        '${response.statusCode} ${response.body}',
      );
    }
    return AudioMeta.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _backgroundDownload(AudioMeta meta) {
    if (_downloading.contains(meta.audioId)) return;
    unawaited(_doDownload(meta));
  }

  Future<void> _doDownload(AudioMeta meta) async {
    if (_downloading.contains(meta.audioId)) return;
    _downloading.add(meta.audioId);
    try {
      await _cache.downloadAndCache(
        audioId: meta.audioId,
        url: meta.url,
        checksumSha256: meta.checksumSha256,
        expectedBytes: meta.bytes,
        contentVersion: meta.audioVersion,
      );
    } finally {
      _downloading.remove(meta.audioId);
    }
  }

  // ── 生命周期 ─────────────────────────────────────────────────────────────

  void dispose() => _player.dispose();
}
