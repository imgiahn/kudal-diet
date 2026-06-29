import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/kudal_status.dart';
import '../kudal_repository.dart';

class ApiKudalRepository implements KudalRepository {
  const ApiKudalRepository(this._client);

  final ApiClient _client;

  @override
  Future<KudalStatus> getKudalStatus() async {
    final json = await _client.get(ApiEndpoints.kudal);
    return KudalStatus.fromJson(json);
  }

  @override
  Future<KudalStatus> petKudal() async {
    return getKudalStatus();
  }

  @override
  Future<List<String>> getCheerMessages() async {
    final status = await getKudalStatus();
    return [status.message];
  }
}
