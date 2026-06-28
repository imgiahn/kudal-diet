import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/user.dart';
import '../user_repository.dart';

class ApiUserRepository implements UserRepository {
  const ApiUserRepository(this._client);

  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<User> getUser() async {
    // 유저 조회 API 미구현 — 시드 유저 데이터 고정
    return User(
      id: AppConfig.userId,
      name: '기안',
      targetWeight: 65.0,
      targetCalories: AppConfig.targetCalories,
      targetCarb: 225,
      targetProtein: 113,
      targetFat: 50,
    );
  }

  @override
  Future<void> updateUser(User user) async {}
}
