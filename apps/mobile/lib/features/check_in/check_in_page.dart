import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

/// CheckInPage - 签到
///
/// Phase 3 implementation with check-in functionality.
class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final ApiClient _apiClient = ApiClient();
  CheckInResult? _checkInResult;
  bool _isLoading = false;
  String? _error;
  bool _hasCheckedIn = false;

  @override
  void initState() {
    super.initState();
    // Note: In real implementation, we would query today's check-in status
    // from backend on mount
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final idempotencyKey = 'checkin-${DateTime.now().millisecondsSinceEpoch}';
      final result = await _apiClient.checkIn(idempotencyKey: idempotencyKey);

      setState(() {
        _checkInResult = result;
        _hasCheckedIn = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('签到'),
      ),
      body: _isLoading && !_hasCheckedIn
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
                        onPressed: () => setState(() => _error = null),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Check-in status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    _hasCheckedIn ? Icons.check_circle : Icons.calendar_today,
                    size: 64,
                    color: _hasCheckedIn ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasCheckedIn ? '今日已签到' : '今日签到',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasCheckedIn
                        ? '签到成功，继续保持！'
                        : '点击按钮完成今日签到',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Streak card
          if (_checkInResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '连续签到',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_checkInResult!.streak.currentStreak}',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(color: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '天',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '基于签到连续天数',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Learning day status card
          if (_checkInResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '今日学习',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _checkInResult!.learningDay.learningDayToday
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _checkInResult!.learningDay.learningDayToday
                              ? Colors.green
                              : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _checkInResult!.learningDay.learningDayToday
                              ? '今日有有效学习'
                              : '今日暂无有效学习',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '有效学习/复习后自动更新',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Important notice
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '签到说明',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• 签到成功 ≠ 学习日成立',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• 学习日需要至少 1 次有效学习/复习',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• 连续天数基于签到计算',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action button
          if (!_hasCheckedIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('立即签到'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Refresh or navigate back
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('返回'),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
