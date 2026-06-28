import 'macro_nutrient.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return '아침';
      case MealType.lunch:
        return '점심';
      case MealType.dinner:
        return '저녁';
      case MealType.snack:
        return '간식';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }

  String get apiKey {
    switch (this) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.lunch:
        return 'lunch';
      case MealType.dinner:
        return 'dinner';
      case MealType.snack:
        return 'snack';
    }
  }
}

class Meal {
  final String id;
  final String name;
  final String amount; // 표시용 문자열 ("150g", "1개")
  final double weightG; // 수치 중량 (g 단위, 불명확 시 0)
  final int calories;
  final double carb;
  final double protein;
  final double fat;
  final int quantity;

  const Meal({
    required this.id,
    required this.name,
    required this.amount,
    this.weightG = 0.0,
    required this.calories,
    this.carb = 0,
    this.protein = 0,
    this.fat = 0,
    this.quantity = 1,
  });

  Meal copyWith({
    String? name,
    String? amount,
    double? weightG,
    int? calories,
    double? carb,
    double? protein,
    double? fat,
    int? quantity,
  }) =>
      Meal(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        weightG: weightG ?? this.weightG,
        calories: calories ?? this.calories,
        carb: carb ?? this.carb,
        protein: protein ?? this.protein,
        fat: fat ?? this.fat,
        quantity: quantity ?? this.quantity,
      );

  MacroNutrient get macro => MacroNutrient(
        carb: carb * quantity,
        protein: protein * quantity,
        fat: fat * quantity,
        calories: calories * quantity,
      );

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: json['amount'] as String,
        calories: json['calories'] as int,
        carb: (json['carb'] as num? ?? 0).toDouble(),
        protein: (json['protein'] as num? ?? 0).toDouble(),
        fat: (json['fat'] as num? ?? 0).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
      );

  // API MealItemResponse → Meal
  factory Meal.fromMealItem(Map<String, dynamic> json) {
    final wg = (json['weight_g'] as num?)?.toDouble() ?? 0.0;
    return Meal(
      id: json['id'] as String,
      name: json['food_name'] as String,
      amount: wg > 0 ? '${wg.toInt()}g' : '',
      weightG: wg,
      calories: json['kcal'] as int,
      carb: (json['carb_g'] as num? ?? 0).toDouble(),
      protein: (json['protein_g'] as num? ?? 0).toDouble(),
      fat: (json['fat_g'] as num? ?? 0).toDouble(),
      quantity: 1,
    );
  }

  // AI FoodItemSchema → Meal
  factory Meal.fromApiFood(Map<String, dynamic> json) {
    final wg = (json['weight_g'] as num).toDouble();
    return Meal(
      id: '${json['food_name']}_${DateTime.now().millisecondsSinceEpoch}',
      name: json['food_name'] as String,
      amount: '${wg.toInt()}g',
      weightG: wg,
      calories: json['kcal'] as int,
      carb: (json['carb_g'] as num? ?? 0).toDouble(),
      protein: (json['protein_g'] as num? ?? 0).toDouble(),
      fat: (json['fat_g'] as num? ?? 0).toDouble(),
      quantity: 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'calories': calories,
        'carb': carb,
        'protein': protein,
        'fat': fat,
        'quantity': quantity,
      };

  // POST /api/v1/meals items 배열 형식
  Map<String, dynamic> toApiItem() => {
        'food_name': name,
        'weight_g': weightG > 0 ? weightG * quantity : null,
        'kcal': calories * quantity,
        'carb_g': carb * quantity,
        'protein_g': protein * quantity,
        'fat_g': fat * quantity,
      };
}

// AI 분석 결과 래퍼
class MealAnalysisResult {
  final List<Meal> meals;
  final String? kudalComment;
  final String? imageUrl;

  const MealAnalysisResult({
    required this.meals,
    this.kudalComment,
    this.imageUrl,
  });

  MealAnalysisResult copyWithMeals(List<Meal> meals) => MealAnalysisResult(
        meals: meals,
        kudalComment: kudalComment,
        imageUrl: imageUrl,
      );
}

class MealSection {
  final MealType type;
  final List<Meal> meals;

  const MealSection({required this.type, required this.meals});

  String get title => type.label;
  String get emoji => type.emoji;

  int get totalCalories =>
      meals.fold(0, (sum, m) => sum + m.calories * m.quantity);

  MacroNutrient get totalMacro => meals.fold(
        const MacroNutrient.zero(),
        (total, m) => total + m.macro,
      );

  MealSection copyWith({List<Meal>? meals}) =>
      MealSection(type: type, meals: meals ?? this.meals);

  factory MealSection.fromJson(Map<String, dynamic> json) => MealSection(
        type: MealType.values.firstWhere(
          (t) => t.apiKey == json['type'],
          orElse: () => MealType.snack,
        ),
        meals: (json['meals'] as List<dynamic>)
            .map((m) => Meal.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'type': type.apiKey,
        'meals': meals.map((m) => m.toJson()).toList(),
      };
}
