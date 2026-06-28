class MacroNutrient {
  final double carb;
  final double protein;
  final double fat;
  final int calories;

  const MacroNutrient({
    required this.carb,
    required this.protein,
    required this.fat,
    required this.calories,
  });

  const MacroNutrient.zero()
      : carb = 0,
        protein = 0,
        fat = 0,
        calories = 0;

  MacroNutrient operator +(MacroNutrient other) => MacroNutrient(
        carb: carb + other.carb,
        protein: protein + other.protein,
        fat: fat + other.fat,
        calories: calories + other.calories,
      );

  factory MacroNutrient.fromJson(Map<String, dynamic> json) => MacroNutrient(
        carb: (json['carb'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        calories: json['calories'] as int,
      );

  Map<String, dynamic> toJson() => {
        'carb': carb,
        'protein': protein,
        'fat': fat,
        'calories': calories,
      };
}
