import '../models/kudal_status.dart';

abstract class KudalRepository {
  /// 쿠달이 현재 상태 조회
  Future<KudalStatus> getKudalStatus();

  /// 쿠달이 쓰다듬기 → 업데이트된 상태 반환
  Future<KudalStatus> petKudal();

  /// 오늘의 응원 메시지 목록 조회
  Future<List<String>> getCheerMessages();
}
