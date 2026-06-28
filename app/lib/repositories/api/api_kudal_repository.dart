import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/kudal_status.dart';
import '../kudal_repository.dart';

class ApiKudalRepository implements KudalRepository {
  const ApiKudalRepository(this._client);

  final ApiClient _client;

  @override
  Future<KudalStatus> getKudalStatus() async {
    final json = await _client.get(ApiEndpoints.kudal, queryParams: {
      'user_id': AppConfig.userId,
    });
    return KudalStatus.fromJson(json);
  }

  @override
  Future<KudalStatus> petKudal() async {
    // FastAPI에 pet 엔드포인트 없음 → 현재 상태 반환
    return getKudalStatus();
  }

  @override
  Future<List<String>> getCheerMessages() async {
    final status = await getKudalStatus();
    return [status.message];
  }
}
