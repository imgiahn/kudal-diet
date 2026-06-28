class KudalStatus {
  final int level;
  final int exp;
  final int maxExp;
  final String mood;
  final String message;
  final int streakDays;
  final int savedMeals;
  final int totalCaloriesBurned;

  const KudalStatus({
    required this.level,
    required this.exp,
    required this.maxExp,
    required this.mood,
    required this.message,
    required this.streakDays,
    required this.savedMeals,
    required this.totalCaloriesBurned,
  });

  double get expRatio => (exp / maxExp).clamp(0.0, 1.0);

  KudalStatus copyWith({
    int? exp,
    String? mood,
    String? message,
  }) =>
      KudalStatus(
        level: level,
        exp: exp ?? this.exp,
        maxExp: maxExp,
        mood: mood ?? this.mood,
        message: message ?? this.message,
        streakDays: streakDays,
        savedMeals: savedMeals,
        totalCaloriesBurned: totalCaloriesBurned,
      );

  factory KudalStatus.fromJson(Map<String, dynamic> json) => KudalStatus(
        level: json['level'] as int? ?? 1,
        exp: json['exp'] as int? ?? 0,
        // API에는 max_exp 없음 → level당 100 EXP
        maxExp: json['max_exp'] as int? ?? 100,
        mood: json['mood'] as String? ?? '응원',
        // API는 last_message, Mock은 message
        message: (json['last_message'] ?? json['message'] ?? '안녕! 나는 쿠달이야 🐾') as String,
        streakDays: json['streak_days'] as int? ?? 0,
        savedMeals: json['saved_meals'] as int? ?? 0,
        totalCaloriesBurned: json['total_calories_burned'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'exp': exp,
        'max_exp': maxExp,
        'mood': mood,
        'message': message,
        'streak_days': streakDays,
        'saved_meals': savedMeals,
        'total_calories_burned': totalCaloriesBurned,
      };
}
