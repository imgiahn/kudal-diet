import '../../core/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../models/user.dart';
import '../user_repository.dart';

class ApiUserRepository implements UserRepository {
  const ApiUserRepository(this._client);

  final ApiClient _client;

  @override
  Future<User> getUser() async {
    final json = await _client.get('/api/v1/users/me');
    return User(
      id: json['id'] as String,
      name: json['nickname'] as String,
      targetWeight: (json['target_weight_kg'] as num?)?.toDouble() ?? 65.0,
      targetCalories: json['daily_kcal_goal'] as int? ?? AppConfig.targetCalories,
      targetCarb: 225,
      targetProtein: 113,
      targetFat: 50,
    );
  }

  @override
  Future<void> updateUser(User user) async {}
}
