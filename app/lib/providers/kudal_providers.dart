import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kudal_status.dart';
import 'repository_providers.dart';

class KudalNotifier extends StateNotifier<AsyncValue<KudalStatus>> {
  KudalNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = await AsyncValue.guard(
      () => _ref.read(kudalRepositoryProvider).getKudalStatus(),
    );
  }

  Future<void> pet() async {
    state = await AsyncValue.guard(
      () => _ref.read(kudalRepositoryProvider).petKudal(),
    );
  }

  Future<List<String>> getCheerMessages() {
    return _ref.read(kudalRepositoryProvider).getCheerMessages();
  }
}

final kudalProvider =
    StateNotifierProvider<KudalNotifier, AsyncValue<KudalStatus>>((ref) {
  return KudalNotifier(ref);
});
