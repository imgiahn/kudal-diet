import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'repository_providers.dart';

final currentUserProvider = FutureProvider<User>((ref) {
  return ref.watch(userRepositoryProvider).getUser();
});
