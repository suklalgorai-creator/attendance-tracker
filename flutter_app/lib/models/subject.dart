class Subject {
  final String id;
  String name;
  int attended;
  int total;
  double targetPercentage;

  Subject({
    required this.id,
    required this.name,
    this.attended = 0,
    this.total = 0,
    this.targetPercentage = 75.0,
  });

  double get percentage {
    if (total == 0) return 100.0;
    return (attended / total) * 100.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'attended': attended,
      'total': total,
      'targetPercentage': targetPercentage,
    };
  }

  factory Subject.fromMap(Map<dynamic, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String,
      attended: (map['attended'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      targetPercentage: (map['targetPercentage'] as num?)?.toDouble() ?? 75.0,
    );
  }
}
