enum AppEnvironment { mock, simulator, development, production }

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;

  const AppConfig._({required this.environment, required this.baseUrl});

  static const mock = AppConfig._(
    environment: AppEnvironment.mock,
    baseUrl: '',
  );

  // iOS 시뮬레이터 (Mac에서 flutter run)
  static const simulator = AppConfig._(
    environment: AppEnvironment.simulator,
    baseUrl: 'http://localhost:8000',
  );

  // 실기기 (iPhone) — EC2 공개 IP
  static const development = AppConfig._(
    environment: AppEnvironment.development,
    baseUrl: 'http://13.61.144.167:8000',
  );

  static const production = AppConfig._(
    environment: AppEnvironment.production,
    baseUrl: 'https://api.kudal.app',
  );

  // ↓↓ 환경 전환: 이 한 줄만 바꾼다 ↓↓
  // mock       → MockRepository, 네트워크 없음
  // simulator  → localhost:8000 (Mac 시뮬레이터)
  // development → EC2 실기기 테스트
  // production  → HTTPS 운영 서버
  static const current = AppConfig.development;

  // 로그인 없음 — 시드 유저 UUID 고정
  static const userId = 'a3cc4044-4a6b-4613-bccc-fd3881de2484';

  // 시드 유저 일일 칼로리 목표
  static const targetCalories = 1800;

  bool get isMock => environment == AppEnvironment.mock;

  // 개발/시뮬레이터 모드에서 Dio 로그 활성화
  bool get isLoggingEnabled =>
      environment == AppEnvironment.development ||
      environment == AppEnvironment.simulator;
}
