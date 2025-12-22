import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/parental_control_service.dart';

class UsageStatisticsScreen extends StatefulWidget {
  const UsageStatisticsScreen({super.key});

  @override
  State<UsageStatisticsScreen> createState() => _UsageStatisticsScreenState();
}

class _UsageStatisticsScreenState extends State<UsageStatisticsScreen> {
  final StorageService _storageService = StorageService();
  final ParentalControlService _parentalService = ParentalControlService();
  
  Map<String, dynamic> _dailyUsage = {};
  Map<String, dynamic> _weeklyUsage = {};
  int _dailyLimit = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final daily = await _storageService.getDailyUsage();
    final weekly = await _storageService.getWeeklyUsage();
    final settings = await _parentalService.getSettings();
    
    setState(() {
      _dailyUsage = daily;
      _weeklyUsage = weekly;
      _dailyLimit = settings.dailyTimeLimitMinutes ?? 0;
      _isLoading = false;
    });
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  int _getTotalWeeklyMinutes() {
    final dailyUsage = _weeklyUsage['dailyUsage'] as Map<String, dynamic>? ?? {};
    int total = 0;
    for (final value in dailyUsage.values) {
      total += value as int? ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dailyMinutes = _dailyUsage['minutesUsed'] as int? ?? 0;
    final weeklyTotal = _getTotalWeeklyMinutes();
    final dailyLimit = _dailyLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Usage Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Usage',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(dailyMinutes),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'Time watched',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (dailyLimit > 0) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(dailyLimit),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Daily limit',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (dailyLimit > 0) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: dailyMinutes / dailyLimit,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((dailyMinutes / dailyLimit) * 100).toStringAsFixed(0)}% of daily limit used',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Weekly Usage Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Week\'s Usage',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatTime(weeklyTotal),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Total time watched this week',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Daily Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDailyBreakdown(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final dailyUsage = _weeklyUsage['dailyUsage'] as Map<String, dynamic>? ?? {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    int maxMinutes = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final minutes = dailyUsage[dateStr] as int? ?? 0;
      if (minutes > maxMinutes) maxMinutes = minutes;
    }

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final dateStr = date.toIso8601String().split('T')[0];
          final minutes = dailyUsage[dateStr] as int? ?? 0;
          final height = maxMinutes > 0 ? (minutes / maxMinutes) : 0.0;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: 150 * height,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Center(
                  child: minutes > 0
                      ? Text(
                          '${minutes}m',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    final dailyUsage = _weeklyUsage['dailyUsage'] as Map<String, dynamic>? ?? {};
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final dateStr = date.toIso8601String().split('T')[0];
        final minutes = dailyUsage[dateStr] as int? ?? 0;
        final isToday = dateStr == now.toIso8601String().split('T')[0];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _formatTime(minutes),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

