/// Domain entity representing a Sticky Note.
/// Replicates React `notes` array schema.
class NoteEntity {
  final String id;
  final String content;
  final String color;
  final DateTime? reminderDate;
  final DateTime createdAt;

  const NoteEntity({
    required this.id,
    required this.content,
    this.color = 'var(--input-bg)',
    this.reminderDate,
    required this.createdAt,
  });

  NoteEntity copyWith({
    String? id,
    String? content,
    String? color,
    DateTime? reminderDate,
    bool clearReminder = false,
    DateTime? createdAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      content: content ?? this.content,
      color: color ?? this.color,
      reminderDate: clearReminder ? null : (reminderDate ?? this.reminderDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEntity &&
          id == other.id &&
          content == other.content &&
          color == other.color &&
          reminderDate == other.reminderDate &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      content.hashCode ^
      color.hashCode ^
      reminderDate.hashCode ^
      createdAt.hashCode;
}
