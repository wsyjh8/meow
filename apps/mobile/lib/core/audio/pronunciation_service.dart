import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 单词发音服务（带本地预加载缓存）。
///
/// 默认声线：美式男声（locale=en-US，voice=am_michael）。
///
/// 缓存策略 — 滑动窗口预加载：
///   1. 进入学习/复习页时，提前下载后续 5 个单词的 WAV 到本地临时目录
///   2. 每评完一个词，再预加载 1 个新词（窗口向前滑动）
///   3. 播放时优先从本地缓存读取（[DeviceFileSource]），无缓存才走网络
///   4. 缓存目录由系统管理（[getTemporaryDirectory]），应用退出后自动清理
class PronunciationService {
  final AudioPlayer _player = AudioPlayer();

  /// 模拟器内通过 10.0.2.2 访问宿主机上运行的 API（端口 3000）。
  /// 真机调试时须改为局域网 IP，例如 http://192.168.1.x:3000/api/v1。
  static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';

  /// 已缓存文件索引：word (lowercase) → 本地文件路径。
  final Map<String, String> _cache = {};

  /// 正在下载中的 word 集合，防止同一个词被重复下载。
  final Set<String> _downloading = {};

  /// 缓存目录路径（懒初始化）。
  String? _cacheDir;

  /// 当前播放器状态变化流。
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  // ── 播放 ────────────────────────────────────────────────────────────────────

  /// 播放 [wordText] 的发音。
  ///
  /// 优先从本地缓存播放（[DeviceFileSource]），无缓存则回退到网络流
  /// （[UrlSource]）。播放失败时 stop() 重置状态后 rethrow。
  Future<void> play(String wordText) async {
    final key = wordText.toLowerCase().trim();
    try {
      // 1. 尝试本地缓存
      if (_cache.containsKey(key)) {
        final filePath = _cache[key]!;
        if (await File(filePath).exists()) {
          await _player.play(DeviceFileSource(filePath));
          return;
        }
        // 文件被系统清理 — 移除失效索引
        _cache.remove(key);
      }
      // 2. 回退到网络流（无缓存 / 缓存未命中）
      final word = Uri.encodeComponent(key);
      final url = '$_baseUrl/pronunciation/$word?locale=en-US&voice=am_michael';
      await _player.play(UrlSource(url));
    } catch (e) {
      await _player.stop().catchError((_) {});
      rethrow;
    }
  }

  // ── 预加载 ──────────────────────────────────────────────────────────────────

  /// 预加载 [wordTexts] 列表中所有单词的发音文件到本地缓存。
  ///
  /// - 已缓存 / 正在下载中的词自动跳过
  /// - 下载失败静默忽略（播放时会回退到网络流）
  /// - 调用方无需 await（fire-and-forget）
  void prefetch(List<String> wordTexts) {
    for (final wt in wordTexts) {
      final key = wt.toLowerCase().trim();
      if (key.isEmpty || _cache.containsKey(key) || _downloading.contains(key)) {
        continue;
      }
      _downloadToCache(key);
    }
  }

  /// 下载单个词的 WAV 文件到缓存目录。
  Future<void> _downloadToCache(String key) async {
    _downloading.add(key);
    try {
      final dir = await _ensureCacheDir();
      final word = Uri.encodeComponent(key);
      final url = Uri.parse(
        '$_baseUrl/pronunciation/$word?locale=en-US&voice=am_michael',
      );
      final response = await http.get(url);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final filePath = '$dir/$key.wav';
        await File(filePath).writeAsBytes(response.bodyBytes);
        _cache[key] = filePath;
      }
    } catch (_) {
      // 下载失败 — 播放时会走 UrlSource 回退
    } finally {
      _downloading.remove(key);
    }
  }

  /// 确保缓存目录存在，返回路径。
  Future<String> _ensureCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/pronunciation_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir.path;
    return _cacheDir!;
  }

  // ── 生命周期 ────────────────────────────────────────────────────────────────

  /// 释放底层 [AudioPlayer] 资源。在 Widget.dispose() 中调用。
  void dispose() => _player.dispose();
}
