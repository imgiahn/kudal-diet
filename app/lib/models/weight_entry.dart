class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;
  final String? note;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.note,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String,
        // API: record_date, Mock: date
        date: DateTime.parse((json['record_date'] ?? json['date']) as String),
        // API: weight_kg, Mock: weight
        weight: ((json['weight_kg'] ?? json['weight']) as num).toDouble(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        if (note != null) 'note': note,
      };
}
