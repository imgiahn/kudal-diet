import 'dart:io';
import '../../models/meal.dart';
import '../../models/macro_nutrient.dart';
import '../meal_repository.dart';

class MockMealRepository implements MealRepository {
  final Map<String, List<MealSection>> _store = {};

  List<MealSection> _defaultSections() => [
        MealSection(
          type: MealType.breakfast,
          meals: [
            const Meal(id: 'm1', name: '오트밀', amount: '100g', calories: 370, carb: 60, protein: 13, fat: 7),
            const Meal(id: 'm2', name: '바나나', amount: '1개', calories: 89, carb: 23, protein: 1, fat: 0),
          ],
        ),
        MealSection(
          type: MealType.lunch,
          meals: [
            const Meal(id: 'm3', name: '현미밥', amount: '150g', calories: 270, carb: 56, protein: 5, fat: 1),
            const Meal(id: 'm4', name: '닭가슴살 구이', amount: '100g', calories: 165, carb: 0, protein: 31, fat: 4),
            const Meal(id: 'm5', name: '된장찌개', amount: '1그릇', calories: 80, carb: 8, protein: 6, fat: 3),
          ],
        ),
        MealSection(type: MealType.dinner, meals: []),
        MealSection(
          type: MealType.snack,
          meals: [
            const Meal(id: 'm6', name: '그릭요거트', amount: '150g', calories: 100, carb: 6, protein: 17, fat: 1),
          ],
        ),
      ];

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<MealSection>> getMealsByDate(DateTime date) async {
    return _store[_dateKey(date)] ?? _defaultSections();
  }

  @override
  Future<MacroNutrient> getDailyMacro(DateTime date) async {
    final sections = await getMealsByDate(date);
    return sections.fold(const MacroNutrient.zero(), (total, s) => total + s.totalMacro);
  }

  @override
  Future<void> saveMeal({required DateTime date, required MealType type, required Meal meal}) async {
    final key = _dateKey(date);
    final sections = List<MealSection>.from(_store[key] ?? _defaultSections());
    final idx = sections.indexWhere((s) => s.type == type);
    if (idx == -1) return;
    final updated = List<Meal>.from(sections[idx].meals)..add(meal);
    sections[idx] = sections[idx].copyWith(meals: updated);
    _store[key] = sections;
  }

  @override
  Future<void> saveMealsBatch({
    required DateTime date,
    required MealType type,
    required List<Meal> meals,
    String? imageUrl,
  }) async {
    for (final meal in meals) {
      await saveMeal(date: date, type: type, meal: meal);
    }
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    for (final key in _store.keys) {
      _store[key] = _store[key]!.map((s) {
        final filtered = s.meals.where((m) => m.id != mealId).toList();
        return s.copyWith(meals: filtered);
      }).toList();
    }
  }

  @override
  Future<MealAnalysisResult> analyzeImage(File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const MealAnalysisResult(
      kudalComment: '오늘도 건강한 식단이네요! 🐾',
      meals: [
        Meal(id: 'a1', name: '현미밥', amount: '150g', calories: 270, carb: 56, protein: 5, fat: 1),
        Meal(id: 'a2', name: '닭가슴살', amount: '100g', calories: 165, carb: 0, protein: 31, fat: 4),
        Meal(id: 'a3', name: '계란후라이', amount: '1개', calories: 90, carb: 0, protein: 7, fat: 7),
        Meal(id: 'a4', name: '방울토마토', amount: '한 줌', calories: 25, carb: 5, protein: 1, fat: 0),
      ],
    );
  }
}
