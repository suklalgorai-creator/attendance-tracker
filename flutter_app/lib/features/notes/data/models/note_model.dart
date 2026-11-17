import '../../domain/entities/note_entity.dart';

/// Data model for Sticky Note serialization, extending NoteEntity.
class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.content,
    super.color,
    super.reminderDate,
    required super.createdAt,
  });

  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      content: entity.content,
      color: entity.color,
      reminderDate: entity.reminderDate,
      createdAt: entity.createdAt,
    );
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: (map['id'] as String?)?.trim() ?? '',
      content: (map['content'] as String?)?.trim() ?? '',
      color: (map['color'] as String?)?.trim() ?? 'var(--input-bg)',
      reminderDate: map['reminderDate'] != null
          ? DateTime.tryParse(map['reminderDate'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'color': color,
      'reminderDate': reminderDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
