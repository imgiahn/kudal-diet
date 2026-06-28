import '../../models/user.dart';
import '../user_repository.dart';

class MockUserRepository implements UserRepository {
  User _user = const User(
    id: 'u1',
    name: '기안',
    targetWeight: 65.0,
    targetCalories: 1800,
    targetCarb: 150,
    targetProtein: 120,
    targetFat: 50,
  );

  @override
  Future<User> getUser() async => _user;

  @override
  Future<void> updateUser(User user) async {
    _user = user;
  }
}
