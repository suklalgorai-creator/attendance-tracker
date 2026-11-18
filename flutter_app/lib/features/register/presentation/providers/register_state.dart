import 'package:flutter/foundation.dart';
import '../../../../shared/widgets/view_toggles_widget.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';

@immutable
class RegisterState {
  final RegisterViewMode viewMode;
  final List<String> visibleDates;
  final Map<String, LegacyAttendanceEntity> legacyByDate;
  final bool isLoading;
  final String? errorMessage;

  const RegisterState({
    this.viewMode = RegisterViewMode.week,
    this.visibleDates = const [],
    this.legacyByDate = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterViewMode? viewMode,
    List<String>? visibleDates,
    Map<String, LegacyAttendanceEntity>? legacyByDate,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterState(
      viewMode: viewMode ?? this.viewMode,
      visibleDates: visibleDates ?? this.visibleDates,
      legacyByDate: legacyByDate ?? this.legacyByDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterState &&
          viewMode == other.viewMode &&
          listEquals(visibleDates, other.visibleDates) &&
          mapEquals(legacyByDate, other.legacyByDate) &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      viewMode.hashCode ^
      Object.hashAll(visibleDates) ^
      Object.hashAll(legacyByDate.entries) ^
      isLoading.hashCode ^
      errorMessage.hashCode;
}
