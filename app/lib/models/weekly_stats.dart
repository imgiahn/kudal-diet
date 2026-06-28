class WeeklyStats {
  final List<double> dailyCalories;
  final List<String> dayLabels;
  final int streakDays;
  final double goalRate;
  final int targetCalories;

  const WeeklyStats({
    required this.dailyCalories,
    required this.dayLabels,
    required this.streakDays,
    required this.goalRate,
    required this.targetCalories,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) => WeeklyStats(
        dailyCalories: (json['daily_calories'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
        dayLabels: (json['day_labels'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        streakDays: json['streak_days'] as int,
        goalRate: (json['goal_rate'] as num).toDouble(),
        targetCalories: json['target_calories'] as int,
      );

  Map<String, dynamic> toJson() => {
        'daily_calories': dailyCalories,
        'day_labels': dayLabels,
        'streak_days': streakDays,
        'goal_rate': goalRate,
        'target_calories': targetCalories,
      };
}
