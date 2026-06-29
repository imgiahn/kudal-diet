import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../core/auth/token_storage.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';

// ── 상태 ──────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? nickname;

  const AuthState({required this.status, this.userId, this.nickname});

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ── Provider ──────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// ── Notifier ──────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref)
      : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  final Ref _ref;
  TokenStorage get _storage => _ref.read(tokenStorageProvider);

  Future<void> _init() async {
    if (AppConfig.current.isMock) {
      state = const AuthState(
        status: AuthStatus.authenticated,
        userId: 'mock-user',
        nickname: '기안',
      );
      return;
    }
    final token = await _storage.getToken();
    if (token != null) {
      final userId = await _storage.getUserId();
      final nickname = await _storage.getNickname();
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: userId,
        nickname: nickname,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithKakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    final client = ApiClient(config: AppConfig.current);
    final resp = await client.post('/api/v1/auth/kakao', body: {
      'kakao_token': token.accessToken,
    });

    final accessToken = resp['access_token'] as String;
    final userId = resp['user_id'] as String;
    final nickname = resp['nickname'] as String;

    await _storage.save(
      token: accessToken,
      userId: userId,
      nickname: nickname,
    );

    state = AuthState(
      status: AuthStatus.authenticated,
      userId: userId,
      nickname: nickname,
    );
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
