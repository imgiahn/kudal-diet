import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _loginKakao() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).loginWithKakao();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인에 실패했어요: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 캐릭터 + 타이틀
              const Text('🐾', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              const Text(
                '쿠달이',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '쿠달이와 함께 건강한 하루를\n기록해보세요 🌿',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF3A2E2A).withOpacity(0.5),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              // 카카오 로그인 버튼
              _KakaoLoginButton(
                onTap: _loginKakao,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _KakaoLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _KakaoLoginButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE500),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C1E1E)),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오 로고 (텍스트 대체)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3C1E1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          color: Color(0xFFFEE500),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '카카오로 계속하기',
                    style: TextStyle(
                      color: Color(0xFF3C1E1E),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
