import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

/// SessionPage - 会话管理
///
/// Phase 3 implementation with session start/finish/validation.
class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final ApiClient _apiClient = ApiClient();
  SessionInfo? _session;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    // For simplicity, we don't track existing session across app restarts
    // In real implementation, this would query backend for active session
    setState(() {});
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final idempotencyKey = 'session-start-${DateTime.now().millisecondsSinceEpoch}';
      final session = await _apiClient.startSession(
        sessionMinutesTarget: 15,
        idempotencyKey: idempotencyKey,
      );

      setState(() {
        _session = session;
        _isLoading = false;
      });

      // Start timer to track elapsed time
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _finishSession() async {
    if (_session == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    _timer?.cancel();

    try {
      final idempotencyKey = 'session-finish-${DateTime.now().millisecondsSinceEpoch}';
      final result = await _apiClient.finishSession(
        sessionId: _session!.sessionId,
        idempotencyKey: idempotencyKey,
      );

      setState(() {
        _session = result;
        _isLoading = false;
      });

      // Show validation result
      if (mounted) {
        _showValidationResult(result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showValidationResult(SessionInfo session) {
    String message;
    IconData icon;
    Color color;

    switch (session.sessionValidationStatus) {
      case 'valid':
        message = '本次 Session 计入有效 Session';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'invalid':
        if (session.actualMinutes != null && session.actualMinutes! < 15) {
          message = '本次 Session 未计入有效 Session（时长不足 15 分钟）';
        } else {
          message = '本次 Session 未计入有效 Session（有效尝试不足 5 次）';
        }
        icon = Icons.info;
        color = Colors.orange;
        break;
      default:
        message = '本次 Session 已结束，正在确认结果';
        icon = Icons.hourglass_empty;
        color = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: color, size: 48),
        title: Text(_getStatusText(session.sessionStatus)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text('有效学习：${session.effectiveLearningCount} 次'),
            Text('有效复习：${session.effectiveReviewCount} 次'),
            if (session.actualMinutes != null)
              Text('实际时长：${session.actualMinutes} 分钟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'started':
        return 'Session 进行中';
      case 'ended':
        return 'Session 已结束';
      default:
        return 'Session 状态未知';
    }
  }

  String _formatElapsed() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注 Session'),
      ),
      body: _isLoading && _session == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('错误：$_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkExistingSession,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_session == null) {
      // No active session - show start button
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              '开始专注',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '目标：15 分钟，至少 5 次有效学习/复习',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('开始 Session'),
              ),
            ),
          ],
        ),
      );
    }

    // Active or completed session
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          // Timer display
          Center(
            child: Text(
              _session!.sessionStatus == 'ended'
                  ? _formatElapsed()
                  : _formatElapsed(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),

          const SizedBox(height: 16),

          // Status
          Center(
            child: _buildStatusChip(
              _session!.sessionStatus,
              _session!.sessionValidationStatus,
            ),
          ),

          const Spacer(),

          // Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '学习统计',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('有效学习', style: TextStyle(color: Colors.grey)),
                            Text('${_session!.effectiveLearningCount} 次',
                                style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('有效复习', style: TextStyle(color: Colors.grey)),
                            Text('${_session!.effectiveReviewCount} 次',
                                style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_session!.actualMinutes != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('实际时长：', style: TextStyle(color: Colors.grey)),
                        Text('${_session!.actualMinutes} 分钟'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action button
          if (_session!.sessionStatus == 'started')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finishSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('结束 Session'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _session = null;
                    _elapsedSeconds = 0;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('开始新 Session'),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String validationStatus) {
    Color color;
    String label;

    if (status == 'ended') {
      switch (validationStatus) {
        case 'valid':
          color = Colors.green;
          label = '有效 Session';
          break;
        case 'invalid':
          color = Colors.orange;
          label = '无效 Session';
          break;
        default:
          color = Colors.grey;
          label = '待确认';
      }
    } else {
      color = Colors.blue;
      label = '进行中';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
