import '../../domain/entities/timetable_session_entity.dart';

/// Serialization model extending [TimetableSessionEntity] with Hive Map conversions.
///
/// Ownership: Timetable Feature (Data Model)
// ==========================================
// TIMETABLE MODEL - Session Map Serialization
// ==========================================
class TimetableModel extends TimetableSessionEntity {
  const TimetableModel({
    required super.id,
    required super.subjectId,
    required super.label,
    required super.dayOfWeek,
    super.active = true,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Creates a model from a domain entity.
  factory TimetableModel.fromEntity(TimetableSessionEntity entity) {
    return TimetableModel(
      id: entity.id,
      subjectId: entity.subjectId,
      label: entity.label,
      dayOfWeek: entity.dayOfWeek,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Deserializes a session from a raw map.
  factory TimetableModel.fromMap(Map<dynamic, dynamic> map, [int? dayOfWeek]) {
    final rawDay = map['dayOfWeek'] ?? dayOfWeek;
    int parsedDay = 0;
    if (rawDay is int) {
      parsedDay = rawDay;
    } else if (rawDay != null) {
      parsedDay = int.tryParse(rawDay.toString()) ?? 0;
    }

    return TimetableModel(
      id: (map['id'] as String?)?.trim() ?? '',
      subjectId: (map['subjectId'] as String?)?.trim() ?? '',
      label: (map['label'] as String?)?.trim() ?? '',
      dayOfWeek: parsedDay,
      active: map['active'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.tryParse(map['deletedAt'].toString())
          : null,
    );
  }

  /// Serializes the model into a standard JSON/Hive map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'label': label,
      'dayOfWeek': dayOfWeek,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Deserializes the full weekly timetable map from a raw Hive map.
  static Map<int, List<TimetableModel>> timetableFromMap(
    Map<dynamic, dynamic>? rawMap,
  ) {
    if (rawMap == null) return {};
    final result = <int, List<TimetableModel>>{};
    rawMap.forEach((key, value) {
      final int? day = key is int ? key : int.tryParse(key.toString());
      if (day == null || day < 0 || day > 6) return;
      if (value is List) {
        final sessions = <TimetableModel>[];
        for (final item in value) {
          if (item is Map) {
            sessions.add(
              TimetableModel.fromMap(Map<dynamic, dynamic>.from(item), day),
            );
          }
        }
        result[day] = sessions;
      }
    });
    return result;
  }

  /// Serializes the full weekly timetable map to a Map with string day keys ("0".."6")
  /// for Schema Version 2 parity.
  static Map<String, dynamic> timetableToMap(
    Map<int, List<TimetableSessionEntity>> timetable,
  ) {
    final result = <String, dynamic>{};
    timetable.forEach((day, sessions) {
      result[day.toString()] = sessions.map((s) {
        if (s is TimetableModel) return s.toMap();
        return TimetableModel.fromEntity(s).toMap();
      }).toList();
    });
    return result;
  }
}

/// Convenience typedef for naming parity.
typedef TimetableSessionModel = TimetableModel;
