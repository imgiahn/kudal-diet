import '../../models/daily_summary.dart';
import '../../models/macro_nutrient.dart';
import '../../models/weekly_stats.dart';
import '../stats_repository.dart';

class MockStatsRepository implements StatsRepository {
  static const _calendarData = [
    (day: 1, status: DayStatus.success, cal: 1680, carb: 120.0, pro: 80.0, fat: 30.0),
    (day: 3, status: DayStatus.warning, cal: 2100, carb: 200.0, pro: 60.0, fat: 50.0),
    (day: 5, status: DayStatus.over,    cal: 2800, carb: 300.0, pro: 40.0, fat: 80.0),
    (day: 10, status: DayStatus.success, cal: 1650, carb: 110.0, pro: 90.0, fat: 25.0),
    (day: 15, status: DayStatus.success, cal: 1670, carb: 115.0, pro: 85.0, fat: 28.0),
    (day: 20, status: DayStatus.warning, cal: 1980, carb: 180.0, pro: 70.0, fat: 45.0),
    (day: 28, status: DayStatus.success, cal: 1620, carb: 98.0,  pro: 88.0, fat: 22.0),
  ];

  @override
  Future<List<DailySummary>> getCalendarData(int year, int month) async {
    return _calendarData
        .map((e) => DailySummary(
              date: DateTime(year, month, e.day),
              status: e.status,
              macro: MacroNutrient(
                calories: e.cal,
                carb: e.carb,
                protein: e.pro,
                fat: e.fat,
              ),
            ))
        .toList();
  }

  @override
  Future<WeeklyStats> getWeeklyStats() async {
    return const WeeklyStats(
      dailyCalories: [1650, 2100, 1800, 1980, 1750, 2050, 1620],
      dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
      streakDays: 12,
      goalRate: 0.78,
      targetCalories: 1800,
    );
  }
}
