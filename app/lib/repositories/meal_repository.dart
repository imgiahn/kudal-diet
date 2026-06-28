import 'dart:io';
import '../models/meal.dart';
import '../models/macro_nutrient.dart';

abstract class MealRepository {
  /// 특정 날짜의 식사 섹션 목록 조회
  Future<List<MealSection>> getMealsByDate(DateTime date);

  /// 특정 날짜의 영양소 합계 조회
  Future<MacroNutrient> getDailyMacro(DateTime date);

  /// 식사 단건 저장
  Future<void> saveMeal({
    required DateTime date,
    required MealType type,
    required Meal meal,
  });

  /// 식사 일괄 저장 (AI 분석 결과 저장 시 단일 요청)
  Future<void> saveMealsBatch({
    required DateTime date,
    required MealType type,
    required List<Meal> meals,
    String? imageUrl,
  });

  /// 식사 삭제
  Future<void> deleteMeal(String mealId);

  /// AI 이미지 분석 → 분석 결과 반환
  Future<MealAnalysisResult> analyzeImage(File imageFile);
}
