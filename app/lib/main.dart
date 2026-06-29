import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/config/app_config.dart';
import 'providers/auth_providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/record_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/kudal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(child: KudalApp()),
  );
}

class KudalApp extends StatelessWidget {
  const KudalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '쿠달이',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4A7B9),
          background: const Color(0xFFFFF8F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
        useMaterial3: true,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth.status) {
      AuthStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const MainNavigator(),
    };
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    StatsScreen(),
    KudalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, '홈'),
              _navItem(1, Icons.edit_note_rounded, '기록'),
              _navItem(2, Icons.bar_chart_rounded, '통계'),
              _navItem(3, Icons.favorite_rounded, '쿠달이'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF4A7B9).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFF4A7B9)
                  : const Color(0xFF3A2E2A).withOpacity(0.4),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFFF4A7B9)
                    : const Color(0xFF3A2E2A).withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
