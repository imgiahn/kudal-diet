import 'package:flutter/material.dart';

String kudalImagePath(String mood) => switch (mood) {
      'happy' => 'assets/images/character/kudal_excited.png',
      'normal' => 'assets/images/character/kudal_love.png',
      'sad' => 'assets/images/character/kudal_relaxed.png',
      'sleepy' => 'assets/images/character/kudal_hello.png',
      _ => 'assets/images/character/kudal_happy.png',
    };

class KudalCard extends StatelessWidget {
  final String message;
  final double size;
  final String mood;

  const KudalCard({
    super.key,
    this.message = '오늘도 화이팅! 쿠달이가 응원해!',
    this.size = 120,
    this.mood = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (size > 0) ...[
          _KudalAvatar(size: size, mood: mood),
          const SizedBox(height: 12),
        ],
        _SpeechBubble(message: message),
      ],
    );
  }
}

class _KudalAvatar extends StatelessWidget {
  final double size;
  final String mood;
  const _KudalAvatar({required this.size, required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF4A7B9).withOpacity(0.15),
        border: Border.all(
          color: const Color(0xFFF4A7B9).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          kudalImagePath(mood),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String message;
  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4A7B9).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF4A7B9).withOpacity(0.3),
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3A2E2A),
              height: 1.4,
            ),
          ),
        ),
        Positioned(
          top: -8,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _BubbleArrowPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF4A7B9).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
