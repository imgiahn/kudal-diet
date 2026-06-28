import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../models/macro_nutrient.dart';
import 'kudal_providers.dart';
import 'repository_providers.dart';
import 'stats_providers.dart';

// 현재 선택된 날짜 (기록 화면에서 공유)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 선택된 날짜의 식사 목록
final mealsProvider = FutureProvider<List<MealSection>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(mealRepositoryProvider).getMealsByDate(date);
});

// 오늘의 영양소 합계 (홈 화면 카드)
final todayMacroProvider = FutureProvider<MacroNutrient>((ref) {
  final today = DateTime.now();
  return ref.watch(mealRepositoryProvider).getDailyMacro(today);
});

// ── AI 분석 상태 ────────────────────────────────────────────

enum AnalysisPhase { idle, analyzing, saving }

class AnalysisState {
  final AsyncValue<MealAnalysisResult> value;
  final AnalysisPhase phase;
  final MealType mealType;

  const AnalysisState({
    required this.value,
    this.phase = AnalysisPhase.idle,
    required this.mealType,
  });

  bool get isSaving => phase == AnalysisPhase.saving;
  bool get isAnalyzing => phase == AnalysisPhase.analyzing;
  bool get isBusy => phase != AnalysisPhase.idle || value.isLoading;

  String get loadingMessage => switch (phase) {
        AnalysisPhase.analyzing => '쿠달이가 식단을 분석하고 있어요... ✨',
        AnalysisPhase.saving => '저장 중이에요...',
        _ => '',
      };

  AnalysisState copyWith({
    AsyncValue<MealAnalysisResult>? value,
    AnalysisPhase? phase,
    MealType? mealType,
  }) =>
      AnalysisState(
        value: value ?? this.value,
        phase: phase ?? this.phase,
        mealType: mealType ?? this.mealType,
      );
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  AnalysisNotifier(this._ref)
      : super(AnalysisState(
          value: const AsyncValue.data(MealAnalysisResult(meals: [])),
          mealType: _defaultMealType(),
        ));

  final Ref _ref;

  static MealType _defaultMealType() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return MealType.breakfast;
    if (h >= 11 && h < 16) return MealType.lunch;
    if (h >= 16 && h < 21) return MealType.dinner;
    return MealType.snack;
  }

  Future<void> analyze(File imageFile) async {
    state = state.copyWith(
      value: const AsyncValue.loading(),
      phase: AnalysisPhase.analyzing,
    );
    final result = await AsyncValue.guard(
      () => _ref.read(mealRepositoryProvider).analyzeImage(imageFile),
    );
    state = state.copyWith(value: result, phase: AnalysisPhase.idle);
  }

  void setMealType(MealType type) {
    state = state.copyWith(mealType: type);
  }

  void updateQuantity(int index, int delta) {
    state.value.whenData((result) {
      final updated = List<Meal>.from(result.meals);
      final item = updated[index];
      final newQty = (item.quantity + delta).clamp(1, 99);
      updated[index] = item.copyWith(quantity: newQty);
      state = state.copyWith(
        value: AsyncValue.data(result.copyWithMeals(updated)),
      );
    });
  }

  void updateMeal(int index, Meal meal) {
    state.value.whenData((result) {
      final updated = List<Meal>.from(result.meals)..[index] = meal;
      state = state.copyWith(
        value: AsyncValue.data(result.copyWithMeals(updated)),
      );
    });
  }

  void deleteMeal(int index) {
    state.value.whenData((result) {
      final updated = List<Meal>.from(result.meals)..removeAt(index);
      state = state.copyWith(
        value: AsyncValue.data(result.copyWithMeals(updated)),
      );
    });
  }

  void addMeal(Meal meal) {
    state.value.whenData((result) {
      final updated = List<Meal>.from(result.meals)..add(meal);
      state = state.copyWith(
        value: AsyncValue.data(result.copyWithMeals(updated)),
      );
    });
  }

  void reset() {
    state = AnalysisState(
      value: const AsyncValue.data(MealAnalysisResult(meals: [])),
      mealType: _defaultMealType(),
    );
  }

  // 저장 실패 시 예외를 rethrow해 UI에서 에러 처리 가능
  Future<void> saveToMeal(DateTime date) async {
    final result = state.value.valueOrNull;
    if (result == null || result.meals.isEmpty) return;
    if (state.isSaving) return; // 중복 클릭 방지

    state = state.copyWith(phase: AnalysisPhase.saving);
    try {
      await _ref.read(mealRepositoryProvider).saveMealsBatch(
            date: date,
            type: state.mealType,
            meals: result.meals,
            imageUrl: result.imageUrl,
          );
      // 저장 성공 → 관련 데이터 전체 갱신
      _ref.invalidate(mealsProvider);
      _ref.invalidate(todayMacroProvider);
      _ref.invalidate(calendarDataProvider);
      _ref.invalidate(weeklyStatsProvider);
      _ref.invalidate(kudalProvider);
    } catch (e) {
      state = state.copyWith(phase: AnalysisPhase.idle);
      rethrow;
    }
    state = state.copyWith(phase: AnalysisPhase.idle);
  }
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier(ref);
});
