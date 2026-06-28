import '../../models/weight_entry.dart';
import '../weight_repository.dart';

class MockWeightRepository implements WeightRepository {
  final List<WeightEntry> _entries = [
    WeightEntry(id: 'w1', date: DateTime(2026, 6, 22), weight: 68.5),
    WeightEntry(id: 'w2', date: DateTime(2026, 6, 23), weight: 68.2),
    WeightEntry(id: 'w3', date: DateTime(2026, 6, 24), weight: 68.0),
    WeightEntry(id: 'w4', date: DateTime(2026, 6, 25), weight: 67.8),
    WeightEntry(id: 'w5', date: DateTime(2026, 6, 26), weight: 67.5),
    WeightEntry(id: 'w6', date: DateTime(2026, 6, 27), weight: 67.3),
    WeightEntry(id: 'w7', date: DateTime(2026, 6, 28), weight: 67.1),
  ];

  @override
  Future<List<WeightEntry>> getWeightHistory({int days = 7}) async {
    final sorted = List<WeightEntry>.from(_entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.take(days).toList();
  }

  @override
  Future<void> saveWeight(WeightEntry entry) async {
    _entries.removeWhere((e) =>
        e.date.year == entry.date.year &&
        e.date.month == entry.date.month &&
        e.date.day == entry.date.day);
    _entries.add(entry);
  }
}
