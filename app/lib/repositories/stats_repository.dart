import '../models/daily_summary.dart';
import '../models/weekly_stats.dart';

abstract class StatsRepository {
  /// 월간 캘린더 데이터 조회 (성공/경고/초과/없음 상태)
  Future<List<DailySummary>> getCalendarData(int year, int month);

  /// 주간 통계 조회 (칼로리, 연속일수, 달성률)
  Future<WeeklyStats> getWeeklyStats();
}
