import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/weight_entry.dart';
import '../weight_repository.dart';

class ApiWeightRepository implements WeightRepository {
  const ApiWeightRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<WeightEntry>> getWeightHistory({int days = 7}) async {
    // GET /api/v1/weights 미구현 — 빈 리스트 반환 (차트 숨김 처리)
    return [];
  }

  @override
  Future<void> saveWeight(WeightEntry entry) async {
    final d = entry.date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _client.post(ApiEndpoints.weights, body: {
      'user_id': AppConfig.userId,
      'weight_kg': entry.weight,
      'record_date': dateStr,
    });
  }
}
