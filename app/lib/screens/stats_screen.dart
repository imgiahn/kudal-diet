import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weekly_stats.dart';
import '../models/weight_entry.dart';
import '../providers/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);
    final weightAsync = ref.watch(weightHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '통계',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              const SizedBox(height: 20),
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    _buildStreakAndGoalRow(stats),
                    const SizedBox(height: 16),
                    _WeeklyCalorieCard(stats: stats),
                  ],
                ),
                loading: () => const _StatsLoadingPlaceholder(),
                error: (e, _) =>
                    Text('통계 로드 실패: $e', style: const TextStyle(color: Color(0xFF3A2E2A))),
              ),
              const SizedBox(height: 16),
              weightAsync.when(
                data: (entries) => _WeightChartCard(entries: entries),
                loading: () => const _StatsLoadingPlaceholder(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakAndGoalRow(WeeklyStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            title: '연속 기록',
            value: '${stats.streakDays}일',
            subtitle: '최고 기록 15일',
            color: const Color(0xFFFFD1A9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '🎯',
            title: '목표 달성률',
            value: '${(stats.goalRate * 100).toInt()}%',
            subtitle: '이번 주 기준',
            color: const Color(0xFFF4A7B9),
          ),
        ),
      ],
    );
  }
}

// ── 통계 카드 ────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF3A2E2A).withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF3A2E2A).withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 주간 칼로리 바 차트 ─────────────────────────────────────

class _WeeklyCalorieCard extends StatelessWidget {
  final WeeklyStats stats;
  const _WeeklyCalorieCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(
      stats.dailyCalories.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: stats.dailyCalories[i],
            color: i == stats.dailyCalories.length - 1
                ? const Color(0xFFF4A7B9)
                : const Color(0xFFE8D5C4),
            width: 22,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '주간 칼로리',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A7B9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '목표 ${stats.targetCalories} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFF4A7B9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE8D5C4).withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= stats.dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          stats.dayLabels[idx],
                          style: TextStyle(
                            fontSize: 12,
                            color: idx == stats.dailyCalories.length - 1
                                ? const Color(0xFFF4A7B9)
                                : const Color(0xFF3A2E2A).withOpacity(0.5),
                            fontWeight:
                                idx == stats.dailyCalories.length - 1
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: stats.targetCalories.toDouble(),
                      color: const Color(0xFFF4A7B9).withOpacity(0.5),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                maxY: 3000,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 체중 변화 라인 차트 ─────────────────────────────────────

class _WeightChartCard extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightChartCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      entries.length,
      (i) => FlSpot(i.toDouble(), entries[i].weight),
    );
    final weightDiff = entries.last.weight - entries.first.weight;
    final diffLabel = weightDiff < 0
        ? '-${weightDiff.abs().toStringAsFixed(1)} kg 감량 🎉'
        : '+${weightDiff.toStringAsFixed(1)} kg';

    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '체중 변화',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              Text(
                diffLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5CB85C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE8D5C4).withOpacity(0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF3A2E2A).withOpacity(0.45),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[idx],
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF3A2E2A).withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFF4A7B9),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFFF4A7B9),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF4A7B9).withOpacity(0.08),
                    ),
                  ),
                ],
                minY: entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 0.5,
                maxY: entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoadingPlaceholder extends StatelessWidget {
  const _StatsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4A7B9)),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
