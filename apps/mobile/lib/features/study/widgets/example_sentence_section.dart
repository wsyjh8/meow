import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart' show WordExample;
import '../../../core/audio/example_audio_service.dart';
import 'section_frame.dart';
import 'study_tokens.dart';

/// 例句 — up to 2 example sentences for the current word.
///
/// Cream-Café spec: English in italic Fraunces (15 / 1.55), Chinese in
/// 13 / inkSoft. Examples are separated by a 1px dashed cream-line divider
/// with vertical padding to give the "handwritten journal" feel.
///
/// Audio play button appears next to each row only when:
///   - [audioService] is non-null (study_page injected it), AND
///   - example.stableId is non-null (data source has the v0.3.0 stable_id field)
/// Otherwise the row renders text only (e.g. legacy bundled assets without
/// stable_id, or examples whose audio_assets row hasn't been generated yet).
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
      emoji: '✍️',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const _DashedDivider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: i == 0 ? 0 : 10),
              child:
                  _ExampleRow(example: shown[i], audioService: audioService),
            ),
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
                style: StudyTokens.serif(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: StudyTokens.ink,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cnPlain,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: StudyTokens.inkSoft,
                  height: 1.5,
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
        ? StudyTokens.inkSoft.withOpacity(0.4)
        : StudyTokens.ink;
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

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 3.0;
    const dashGap = 3.0;
    final paint = Paint()
      ..color = StudyTokens.line
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
