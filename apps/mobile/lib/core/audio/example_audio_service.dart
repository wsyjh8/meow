import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import 'audio_cache_repository.dart';

/// 例句发音服务（v0.3.0 P2.1）。
///
/// 通过 example.stable_id 拿例句音频。
///
/// 关键约束（DB §3.4 / §6.2.2）：
///   - **App 不计算 hash、不拼 URL** —— 通过
///     `GET /api/v1/examples/:stable_id/audio?voice=...` 拿到 url 字段，
///     直接播放，不做任何字符串变换。
///
/// 缓存（共享 [AudioCacheRepository] 实现）：
///   - 持久层 `audio_file_cache` drift 表
///   - 二进制存 `{appDocs}/audio/{audio_id}.mp3`
///   - 触发器 1（容量 + LRU）+ 触发器 2（content_version orphan）
///
/// 失败处理（DB §11）：CDN miss / 下载失败 → 抛 [AudioFetchException]
/// 给调用方（UI 灰按钮）。**不调用系统 TTS 兜底**。
class ExampleAudioService {
  ExampleAudioService({AudioCacheRepository? cache})
      : _cache = cache ?? AudioCacheRepository();

  final AudioCacheRepository _cache;
  final AudioPlayer _player = AudioPlayer();

  /// 模拟器内通过 10.0.2.2 访问宿主机上的 API（端口 3000）。
  /// 真机调试时改为局域网 IP。
  static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';

  /// 当前默认 voice（MVP 阶段写死，P2.2 后可换成用户偏好）。
  static const String _defaultVoice = 'af_bella';

  /// 正在下载中的 audio_id 集合（防重复下载）。
  final Set<String> _downloading = {};

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  // ── 播放 ─────────────────────────────────────────────────────────────────

  /// 播放 [stableId] 例句音频，使用 [voice]（默认 af_bella）。
  ///
  /// 流程：调 API 拿 meta → 查缓存 → 命中 + checksum 匹配 → DeviceFileSource；
  /// 未命中 → UrlSource 流播 + 后台下载入缓存。
  Future<void> play(String stableId, {String voice = _defaultVoice}) async {
    try {
      // ignore: avoid_print
      print('[ExampleAudio] play start stableId=$stableId voice=$voice');
      final meta = await _fetchMeta(stableId, voice);
      // ignore: avoid_print
      print('[ExampleAudio] meta ok audioId=${meta.audioId} url=${meta.url}');
      final cached = await _cache.findByAudioId(meta.audioId);

      if (cached != null && cached.cachedChecksum == meta.checksumSha256) {
        final file = File(cached.localPath);
        if (await file.exists()) {
          await _player.play(DeviceFileSource(cached.localPath));
          await _cache.touchPlayedAt(meta.audioId);
          // ignore: avoid_print
          print('[ExampleAudio] played from cache');
          return;
        }
        // 文件丢失 → 删孤儿元数据，继续走网络流
        await _cache.deleteEntry(meta.audioId);
      }

      await _player.play(UrlSource(meta.url));
      // ignore: avoid_print
      print('[ExampleAudio] streaming + background download');
      _backgroundDownload(meta);
    } catch (e, st) {
      // ignore: avoid_print
      print('[ExampleAudio] play FAILED stableId=$stableId err=$e');
      // ignore: avoid_print
      print(st);
      await _player.stop().catchError((_) {});
      rethrow;
    }
  }

  // ── 预加载 ───────────────────────────────────────────────────────────────

  /// 进词书时预下载策略（DB §7.4.2）的渲染端实现：调用方传将要展示的
  /// stableId 列表，本服务并发拉取（已下载 / 正在下载的跳过）。
  void prefetch(List<String> stableIds, {String voice = _defaultVoice}) {
    for (final id in stableIds) {
      if (id.isEmpty) continue;
      _prefetchOne(id, voice);
    }
  }

  Future<void> _prefetchOne(String stableId, String voice) async {
    try {
      final meta = await _fetchMeta(stableId, voice);
      if (_downloading.contains(meta.audioId)) return;
      final existing = await _cache.findByAudioId(meta.audioId);
      if (existing != null && existing.cachedChecksum == meta.checksumSha256) {
        if (await File(existing.localPath).exists()) return;
      }
      await _doDownload(meta);
    } catch (_) {/* silently — play will retry over network */}
  }

  // ── 内部 ─────────────────────────────────────────────────────────────────

  Future<AudioMeta> _fetchMeta(String stableId, String voice) async {
    final uri = Uri.parse(
      '$_baseUrl/examples/$stableId/audio?voice=$voice&format=mp3',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw AudioFetchException(
        'Failed to fetch example audio meta: '
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

  // ── 用户面 cache ops 转发到 repository ───────────────────────────────────

  Future<int> totalCachedBytes() => _cache.totalCachedBytes();
  Future<void> clearAll() => _cache.clearAll();

  // ── 生命周期 ─────────────────────────────────────────────────────────────

  void dispose() => _player.dispose();
}
