import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_summary.dart';
import '../models/weekly_stats.dart';
import '../models/weight_entry.dart';
import 'repository_providers.dart';

// 월간 캘린더 데이터 (year, month) 키로 캐싱
final calendarDataProvider =
    FutureProvider.family<List<DailySummary>, (int, int)>((ref, ym) {
  return ref.watch(statsRepositoryProvider).getCalendarData(ym.$1, ym.$2);
});

// 주간 통계
final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) {
  return ref.watch(statsRepositoryProvider).getWeeklyStats();
});

// 체중 기록
final weightHistoryProvider = FutureProvider<List<WeightEntry>>((ref) {
  return ref.watch(weightRepositoryProvider).getWeightHistory();
});
