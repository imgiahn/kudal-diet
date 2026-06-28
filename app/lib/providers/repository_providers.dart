import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../repositories/meal_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/stats_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/kudal_repository.dart';
import '../repositories/mock/mock_meal_repository.dart';
import '../repositories/mock/mock_weight_repository.dart';
import '../repositories/mock/mock_stats_repository.dart';
import '../repositories/mock/mock_user_repository.dart';
import '../repositories/mock/mock_kudal_repository.dart';
import '../repositories/api/api_meal_repository.dart';
import '../repositories/api/api_weight_repository.dart';
import '../repositories/api/api_stats_repository.dart';
import '../repositories/api/api_user_repository.dart';
import '../repositories/api/api_kudal_repository.dart';

// ── 인프라 ─────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(config: AppConfig.current);
});

// ── Repository 주입 ────────────────────────────────────────
// Mock → Api 전환: return 줄 하나만 변경

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  if (AppConfig.current.isMock) return MockMealRepository();
  return ApiMealRepository(ref.read(apiClientProvider));
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  if (AppConfig.current.isMock) return MockWeightRepository();
  return ApiWeightRepository(ref.read(apiClientProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  if (AppConfig.current.isMock) return MockStatsRepository();
  return ApiStatsRepository(ref.read(apiClientProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (AppConfig.current.isMock) return MockUserRepository();
  return ApiUserRepository(ref.read(apiClientProvider));
});

final kudalRepositoryProvider = Provider<KudalRepository>((ref) {
  if (AppConfig.current.isMock) return MockKudalRepository();
  return ApiKudalRepository(ref.read(apiClientProvider));
});
