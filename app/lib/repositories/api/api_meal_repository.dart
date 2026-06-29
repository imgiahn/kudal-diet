import 'dart:io';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/meal.dart';
import '../../models/macro_nutrient.dart';
import '../meal_repository.dart';

class ApiMealRepository implements MealRepository {
  const ApiMealRepository(this._client);

  final ApiClient _client;

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<MealSection>> getMealsByDate(DateTime date) async {
    final json = await _client.get(ApiEndpoints.daily, queryParams: {
      'date': _dateStr(date),
    });
    final rawMeals = json['meals'] as List<dynamic>;
    final grouped = <MealType, List<Meal>>{};
    for (final m in rawMeals) {
      final mealMap = m as Map<String, dynamic>;
      final type = MealType.values.firstWhere(
        (t) => t.apiKey == mealMap['meal_type'],
        orElse: () => MealType.snack,
      );
      final items = (mealMap['items'] as List<dynamic>)
          .map((item) => Meal.fromMealItem(item as Map<String, dynamic>))
          .toList();
      grouped.putIfAbsent(type, () => []).addAll(items);
    }
    return MealType.values
        .map((t) => MealSection(type: t, meals: grouped[t] ?? []))
        .toList();
  }

  @override
  Future<MacroNutrient> getDailyMacro(DateTime date) async {
    final json = await _client.get(ApiEndpoints.daily, queryParams: {
      'date': _dateStr(date),
    });
    final summary = json['summary'] as Map<String, dynamic>?;
    if (summary == null) return const MacroNutrient.zero();
    return MacroNutrient(
      calories: summary['total_kcal'] as int? ?? 0,
      carb: (summary['total_carb_g'] as num? ?? 0).toDouble(),
      protein: (summary['total_protein_g'] as num? ?? 0).toDouble(),
      fat: (summary['total_fat_g'] as num? ?? 0).toDouble(),
    );
  }

  @override
  Future<void> saveMeal({
    required DateTime date,
    required MealType type,
    required Meal meal,
  }) async {
    await saveMealsBatch(date: date, type: type, meals: [meal]);
  }

  @override
  Future<void> saveMealsBatch({
    required DateTime date,
    required MealType type,
    required List<Meal> meals,
    String? imageUrl,
  }) async {
    await _client.post(ApiEndpoints.meals, body: {
      'meal_type': type.apiKey,
      'meal_date': _dateStr(date),
      if (imageUrl != null) 'image_url': imageUrl,
      'items': meals.map((m) => m.toApiItem()).toList(),
    });
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    await _client.delete(ApiEndpoints.deleteMeal(mealId));
  }

  @override
  Future<void> deleteMealItem(String itemId) async {
    await _client.delete(ApiEndpoints.deleteMealItem(itemId));
  }

  @override
  Future<void> updateMealItem(String itemId, Meal updated) async {
    await _client.patch(ApiEndpoints.updateMealItem(itemId), body: {
      'food_name': updated.name,
      if (updated.weightG > 0) 'weight_g': updated.weightG,
      'kcal': updated.calories,
      'carb_g': updated.carb,
      'protein_g': updated.protein,
      'fat_g': updated.fat,
    });
  }

  @override
  Future<MealAnalysisResult> analyzeImage(File imageFile) async {
    final json = await _client.postMultipart(
      ApiEndpoints.analyzeMealUpload,
      file: imageFile,
      fields: {},
    );
    final foods = (json['foods'] as List<dynamic>)
        .map((f) => Meal.fromApiFood(f as Map<String, dynamic>))
        .toList();
    return MealAnalysisResult(
      meals: foods,
      kudalComment: json['kudal_comment'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
