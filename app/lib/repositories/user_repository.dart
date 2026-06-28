import '../models/user.dart';

abstract class UserRepository {
  /// 현재 사용자 정보 조회
  Future<User> getUser();

  /// 사용자 정보 수정
  Future<void> updateUser(User user);
}
