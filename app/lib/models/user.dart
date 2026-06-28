class User {
  final String id;
  final String name;
  final double targetWeight;
  final int targetCalories;
  final int targetCarb;
  final int targetProtein;
  final int targetFat;

  const User({
    required this.id,
    required this.name,
    required this.targetWeight,
    required this.targetCalories,
    required this.targetCarb,
    required this.targetProtein,
    required this.targetFat,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        targetWeight: (json['target_weight'] as num).toDouble(),
        targetCalories: json['target_calories'] as int,
        targetCarb: json['target_carb'] as int,
        targetProtein: json['target_protein'] as int,
        targetFat: json['target_fat'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target_weight': targetWeight,
        'target_calories': targetCalories,
        'target_carb': targetCarb,
        'target_protein': targetProtein,
        'target_fat': targetFat,
      };

  User copyWith({
    String? name,
    double? targetWeight,
    int? targetCalories,
    int? targetCarb,
    int? targetProtein,
    int? targetFat,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        targetWeight: targetWeight ?? this.targetWeight,
        targetCalories: targetCalories ?? this.targetCalories,
        targetCarb: targetCarb ?? this.targetCarb,
        targetProtein: targetProtein ?? this.targetProtein,
        targetFat: targetFat ?? this.targetFat,
      );
}
