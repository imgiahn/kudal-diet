import 'macro_nutrient.dart';

enum DayStatus { success, warning, over, empty }

class DailySummary {
  final DateTime date;
  final DayStatus status;
  final MacroNutrient macro;

  const DailySummary({
    required this.date,
    required this.status,
    required this.macro,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    final MacroNutrient macro;
    if (json.containsKey('macro')) {
      macro = MacroNutrient.fromJson(json['macro'] as Map<String, dynamic>);
    } else {
      // API CalendarDaySchema 형식: total_kcal, total_carb_g 등
      macro = MacroNutrient(
        calories: json['total_kcal'] as int? ?? 0,
        carb: (json['total_carb_g'] as num? ?? 0).toDouble(),
        protein: (json['total_protein_g'] as num? ?? 0).toDouble(),
        fat: (json['total_fat_g'] as num? ?? 0).toDouble(),
      );
    }
    return DailySummary(
      date: DateTime.parse(json['date'] as String),
      status: DayStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String?)?.toLowerCase(),
        orElse: () => DayStatus.empty,
      ),
      macro: macro,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'status': status.name,
        'macro': macro.toJson(),
      };
}
