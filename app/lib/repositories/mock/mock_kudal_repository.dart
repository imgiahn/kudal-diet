import '../../models/kudal_status.dart';
import '../kudal_repository.dart';

class MockKudalRepository implements KudalRepository {
  KudalStatus _status = const KudalStatus(
    level: 3,
    exp: 65,
    maxExp: 100,
    mood: '만족',
    message: '오늘 단백질 아주 좋았어!\n저녁은 가볍게 가보자.',
    streakDays: 12,
    savedMeals: 38,
    totalCaloriesBurned: 12400,
  );

  @override
  Future<KudalStatus> getKudalStatus() async => _status;

  @override
  Future<KudalStatus> petKudal() async {
    final newExp = (_status.exp + 5).clamp(0, _status.maxExp);
    _status = _status.copyWith(
      exp: newExp,
      mood: '행복',
      message: '쓰다듬어줘서 기분 좋아! 💕',
    );
    return _status;
  }

  @override
  Future<List<String>> getCheerMessages() async => [
        '오늘 단백질 목표 달성! 쿠달이가 칭찬해요 🌟',
        '물 2L 마셨죠? 피부가 맑아지고 있어요 💧',
        '12일 연속 기록 중! 포기하지 마요 💪',
        '저녁은 가볍게 먹어요. 내일이 더 기대돼요!',
      ];
}
