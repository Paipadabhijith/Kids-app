import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../services/parental_control_service.dart';

class UsageDashboardScreen extends StatefulWidget {
  const UsageDashboardScreen({super.key});

  @override
  State<UsageDashboardScreen> createState() => _UsageDashboardScreenState();
}

class _UsageDashboardScreenState extends State<UsageDashboardScreen> {
  final StorageService _storageService = StorageService();
  final ParentalControlService _parentalService = ParentalControlService();
  
  Map<String, int> _weeklyUsage = {};
  int _todayUsage = 0;
  int _weekTotal = 0;
  int _dailyLimit = 60;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load settings for daily limit
      final settings = await _parentalService.getSettings();
      _dailyLimit = settings.dailyTimeLimitMinutes ?? 60;
      
      // Load today's usage
      _todayUsage = await _storageService.getTodayUsage();
      
      // Load weekly usage (last 7 days)
      final now = DateTime.now();
      final weeklyData = <String, int>{};
      int total = 0;
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final usage = await _storageService.getUsageForDate(date);
        weeklyData[dateKey] = usage;
        total += usage;
      }
      
      setState(() {
        _weeklyUsage = weeklyData;
        _weekTotal = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading usage data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Usage Dashboard'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsageData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Usage Card
            _buildTodayUsageCard(),
            
            const SizedBox(height: 16),
            
            // Weekly Overview Card
            _buildWeeklyOverviewCard(),
            
            const SizedBox(height: 16),
            
            // Weekly Chart
            _buildWeeklyChart(),
            
            const SizedBox(height: 16),
            
            // Statistics Cards
            _buildStatisticsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayUsageCard() {
    final percentUsed = (_todayUsage / _dailyLimit * 100).clamp(0, 100);
    
    Color statusColor;
    IconData statusIcon;
    
    if (percentUsed < 50) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else if (percentUsed < 80) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    }
    
    return Card(
      elevation: 4,
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Usage',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_todayUsage min',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'of $_dailyLimit min limit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percentUsed / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${percentUsed.toInt()}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Icon(statusIcon, color: statusColor, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverviewCard() {
    final avgDaily = _weekTotal / 7;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Weekly Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  '$_weekTotal min',
                  Icons.access_time,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Daily Avg',
                  '${avgDaily.toInt()} min',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildStatItem(
                  'Limit',
                  '$_dailyLimit min',
                  Icons.flag,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Last 7 Days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_dailyLimit * 1.2).toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = _weeklyUsage.keys.elementAt(groupIndex);
                        final day = DateTime.parse(date).day;
                        return BarTooltipItem(
                          'Day $day\n${rod.toY.toInt()} min',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _weeklyUsage.length) {
                            final date = _weeklyUsage.keys.elementAt(value.toInt());
                            final day = DateTime.parse(date);
                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dayNames[day.weekday - 1],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}m',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklyUsage.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final usage = entry.value.value;
                    
                    Color barColor;
                    if (usage > _dailyLimit) {
                      barColor = Colors.red;
                    } else if (usage > _dailyLimit * 0.8) {
                      barColor = Colors.orange;
                    } else {
                      barColor = Colors.green;
                    }
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: usage.toDouble(),
                          color: barColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Under 80%'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, '80-100%'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, 'Over Limit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    final maxDay = _weeklyUsage.entries.reduce((a, b) => a.value > b.value ? a : b);
    final minDay = _weeklyUsage.entries.reduce((a, b) => a.value < b.value ? a : b);
    final daysOverLimit = _weeklyUsage.values.where((v) => v > _dailyLimit).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Highest Day',
                '${maxDay.value} min',
                Icons.arrow_upward,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Lowest Day',
                '${minDay.value} min',
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Over Limit',
                '$daysOverLimit days',
                Icons.warning,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Compliance',
                '${((7 - daysOverLimit) / 7 * 100).toInt()}%',
                Icons.check_circle,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

