import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/daily_summary.dart';
import '../../models/weekly_stats.dart';
import '../stats_repository.dart';
import '../../core/config/app_config.dart';

class ApiStatsRepository implements StatsRepository {
  const ApiStatsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<DailySummary>> getCalendarData(int year, int month) async {
    final json = await _client.get(ApiEndpoints.calendar, queryParams: {
      'year': year.toString(),
      'month': month.toString(),
    });
    return (json['days'] as List<dynamic>)
        .map((d) => DailySummary.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WeeklyStats> getWeeklyStats() async {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    final results = await Future.wait<Map<String, dynamic>>([
      _client.get(ApiEndpoints.calendar, queryParams: {
        'year': now.year.toString(),
        'month': now.month.toString(),
      }),
      _client.get(ApiEndpoints.kudal),
    ]);

    final calDays = (results[0]['days'] as List<dynamic>).cast<Map<String, dynamic>>();
    final kudalJson = results[1];

    final dayLabels = <String>[];
    final dailyCalories = <double>[];
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    int successCount = 0;

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = fmt.format(day);
      final match = calDays.where((d) => d['date'] == dateStr).firstOrNull;
      final kcal = (match?['total_kcal'] as int? ?? 0).toDouble();
      dailyCalories.add(kcal);
      dayLabels.add(weekdays[day.weekday - 1]);
      final status = match?['status'] as String?;
      if (status == 'success' || status == 'warning') successCount++;
    }

    return WeeklyStats(
      dailyCalories: dailyCalories,
      dayLabels: dayLabels,
      streakDays: kudalJson['streak_days'] as int? ?? 0,
      goalRate: successCount / 7,
      targetCalories: AppConfig.targetCalories,
    );
  }
}
