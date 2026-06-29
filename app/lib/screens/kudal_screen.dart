import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kudal_status.dart';
import '../providers/kudal_providers.dart';
import '../widgets/kudal_card.dart';

class KudalScreen extends ConsumerStatefulWidget {
  const KudalScreen({super.key});

  @override
  ConsumerState<KudalScreen> createState() => _KudalScreenState();
}

class _KudalScreenState extends ConsumerState<KudalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  bool _isPetting = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _pet() async {
    setState(() => _isPetting = true);
    await _bounceController.forward();
    await _bounceController.reverse();
    // Repository 호출 → 상태 업데이트
    await ref.read(kudalProvider.notifier).pet();
    setState(() => _isPetting = false);
  }

  Future<void> _showCheer() async {
    final messages =
        await ref.read(kudalProvider.notifier).getCheerMessages();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheerBottomSheet(messages: messages),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kudalAsync = ref.watch(kudalProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: kudalAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4A7B9)),
              strokeWidth: 2,
            ),
          ),
          error: (e, _) => Center(
            child: Text('오류: $e',
                style: const TextStyle(color: Color(0xFF3A2E2A))),
          ),
          data: (status) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(status),
                const SizedBox(height: 32),
                _buildKudalSection(status),
                const SizedBox(height: 24),
                _buildLevelCard(status),
                const SizedBox(height: 16),
                _buildButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(KudalStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '쿠달이',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3A2E2A),
          ),
        ),
        _MoodBadge(mood: status.mood),
      ],
    );
  }

  Widget _buildKudalSection(KudalStatus status) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pet,
          child: ScaleTransition(
            scale: _bounceAnim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isPetting)
                  ...List.generate(5, (i) => _HeartParticle(index: i)),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF4A7B9).withOpacity(0.3),
                        const Color(0xFFF4A7B9).withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF4A7B9).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFFF4A7B9).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      kudalImagePath(status.mood),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '탭해서 쓰다듬어 주세요 💕',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF3A2E2A).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 20),
        _KudalBubble(message: status.message),
      ],
    );
  }

  Widget _buildLevelCard(KudalStatus status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A7B9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lv. ${status.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '건강한 식단 지킴이',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF3A2E2A).withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${status.exp} / ${status.maxExp} EXP',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF3A2E2A).withOpacity(0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: status.expRatio,
              backgroundColor: const Color(0xFFF5F0EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF4A7B9)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: '연속 기록', value: '${status.streakDays}일'),
              _MiniStat(
                  label: '저장한 식단', value: '${status.savedMeals}개'),
              _MiniStat(
                label: '소모 칼로리',
                value: '${status.totalCaloriesBurned.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pet,
            icon: const Text('🐾', style: TextStyle(fontSize: 16)),
            label: const Text('쿠달이 쓰다듬기',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF4A7B9),
              side: const BorderSide(color: Color(0xFFF4A7B9)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showCheer,
            icon: const Text('✨', style: TextStyle(fontSize: 16)),
            label: const Text('오늘 응원 받기',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4A7B9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 서브 위젯 ────────────────────────────────────────────────

class _KudalBubble extends StatelessWidget {
  final String message;
  const _KudalBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4A7B9).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4A7B9).withOpacity(0.3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF3A2E2A),
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  final String mood;
  const _MoodBadge({required this.mood});

  static const _moodEmoji = {
    'happy': '🎉',
    'normal': '💪',
    'sad': '🫶',
    'sleepy': '👋',
  };

  static const _moodLabel = {
    'happy': '아주 잘했어!',
    'normal': '괜찮아!',
    'sad': '내일 다시!',
    'sleepy': '기록해봐!',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4A7B9).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4A7B9).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_moodEmoji[mood] ?? '😊', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            _moodLabel[mood] ?? mood,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF4A7B9),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF4A7B9),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF3A2E2A).withOpacity(0.45),
          ),
        ),
      ],
    );
  }
}

class _HeartParticle extends StatelessWidget {
  final int index;
  const _HeartParticle({required this.index});

  @override
  Widget build(BuildContext context) {
    const offsets = [
      Offset(-40, -60),
      Offset(40, -55),
      Offset(0, -70),
      Offset(-25, -45),
      Offset(30, -65),
    ];
    return Transform.translate(
      offset: offsets[index % offsets.length],
      child: Text('💕', style: TextStyle(fontSize: 16 + index * 2.0)),
    );
  }
}

class _CheerBottomSheet extends StatelessWidget {
  final List<String> messages;
  const _CheerBottomSheet({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5C4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('✨', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              const Text(
                '쿠달이의 오늘 응원',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A2E2A),
                ),
              ),
              const SizedBox(height: 20),
              ...messages.map(
                (msg) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4A7B9).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFF4A7B9).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('🐾', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3A2E2A),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
