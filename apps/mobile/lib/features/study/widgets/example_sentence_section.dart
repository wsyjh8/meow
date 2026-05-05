import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart' show WordExample;
import '../../../core/audio/example_audio_service.dart';
import 'section_frame.dart';
import 'study_tokens.dart';

/// 例句 — up to 2 example sentences for the current word.
///
/// English line is slightly larger (13px / textDark) than the Chinese
/// translation (12px / textGray) — "英主中辅" hierarchy from the
/// typography spec. Brackets used by the source data as highlight
/// markers (`[abandon]`) are stripped for plain rendering.
///
/// Audio play button appears only when:
///   - [audioService] is non-null (study_page injected it), AND
///   - example.stableId is non-null (data source has the v0.3.0 stable_id field)
/// Otherwise the row renders text only (current state for legacy bundled assets).
class ExampleSentenceSection extends StatelessWidget {
  final List<WordExample> examples;
  final ExampleAudioService? audioService;

  const ExampleSentenceSection({
    super.key,
    required this.examples,
    this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    final shown = examples.take(2).toList();
    return SectionFrame(
      title: '例句',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ExampleRow(example: shown[i], audioService: audioService),
          ],
        ],
      ),
    );
  }
}

class _ExampleRow extends StatefulWidget {
  final WordExample example;
  final ExampleAudioService? audioService;
  const _ExampleRow({required this.example, this.audioService});

  @override
  State<_ExampleRow> createState() => _ExampleRowState();
}

class _ExampleRowState extends State<_ExampleRow> {
  bool _isLoading = false;
  bool _failed = false;

  bool get _canPlay =>
      widget.audioService != null && widget.example.stableId != null;

  Future<void> _onPlay() async {
    final service = widget.audioService;
    final stableId = widget.example.stableId;
    if (service == null || stableId == null) return;
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    try {
      await service.play(stableId);
    } catch (_) {
      // 失败 → 灰按钮 + 静默重试由 service 内部处理
      // 这里不弹 toast、不调系统 TTS（DB §11 显式禁令）
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enPlain = widget.example.en.replaceAll(RegExp(r'\[|\]'), '');
    final cnPlain = widget.example.cn.replaceAll(RegExp(r'\[|\]'), '');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enPlain,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: StudyTokens.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                cnPlain,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: StudyTokens.textGray,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (_canPlay) _buildPlayButton(),
      ],
    );
  }

  Widget _buildPlayButton() {
    final iconColor = _failed
        ? StudyTokens.textGray.withOpacity(0.4)
        : StudyTokens.textDark;
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: SizedBox(
        width: 28,
        height: 28,
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            : IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(
                  _failed ? Icons.volume_off : Icons.volume_up,
                  color: iconColor,
                ),
                tooltip: _failed ? '暂时无法加载' : '播放例句',
                onPressed: _failed ? null : _onPlay,
              ),
      ),
    );
  }
}
