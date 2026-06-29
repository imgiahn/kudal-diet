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

  // 실기기 (iPhone) — 빌드 시 --dart-define=EC2_HOST=x.x.x.x 로 주입
  // flutter run --dart-define=EC2_HOST=13.61.144.167
  static const development = AppConfig._(
    environment: AppEnvironment.development,
    baseUrl: 'http://${String.fromEnvironment('EC2_HOST', defaultValue: '13.61.144.167')}:8000',
  );

  static const production = AppConfig._(
    environment: AppEnvironment.production,
    baseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.kudal.app'),
  );

  // ↓↓ 환경 전환: 이 한 줄만 바꾼다 ↓↓
  static const current = AppConfig.development;

  // 빌드 시 --dart-define=KAKAO_NATIVE_APP_KEY=abc123 주입
  static const kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: 'YOUR_KAKAO_NATIVE_APP_KEY');

  // 목표 칼로리 기본값
  static const targetCalories = 1800;

  bool get isMock => environment == AppEnvironment.mock;

  bool get isLoggingEnabled =>
      environment == AppEnvironment.development ||
      environment == AppEnvironment.simulator;
}
