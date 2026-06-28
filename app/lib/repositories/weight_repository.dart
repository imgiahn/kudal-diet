import '../models/weight_entry.dart';

abstract class WeightRepository {
  /// 최근 N일 체중 기록 조회
  Future<List<WeightEntry>> getWeightHistory({int days = 7});

  /// 체중 기록 저장
  Future<void> saveWeight(WeightEntry entry);
}
