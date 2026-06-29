import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/weight_entry.dart';
import '../weight_repository.dart';

class ApiWeightRepository implements WeightRepository {
  const ApiWeightRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<WeightEntry>> getWeightHistory({int days = 7}) async {
    return [];
  }

  @override
  Future<void> saveWeight(WeightEntry entry) async {
    final d = entry.date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _client.post(ApiEndpoints.weights, body: {
      'weight_kg': entry.weight,
      'record_date': dateStr,
    });
  }
}
