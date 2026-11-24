import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sync/presentation/providers/sync_providers.dart';
import '../services/notification_service.dart';
import 'repository_providers.dart';

/// Provider for [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = DefaultNotificationService();
  service.initialize();
  return service;
});

/// Auto-sync notifier that schedules reminders when user settings or holidays update.
final notificationSchedulerProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);

  settingsAsync.whenData((settings) async {
    final remoteDataSource = ref.watch(remoteSyncDataSourceProvider);
    Map<String, dynamic> holidays = {};
    try {
      final global = await remoteDataSource.fetchGlobalSettings();
      if (global['holidays'] is Map) {
        holidays = Map<String, dynamic>.from(global['holidays'] as Map);
      }
    } catch (_) {}

    await notificationService.scheduleAttendanceReminder(
      reminderTime: settings.reminderTime,
      classDays: settings.classDays,
      isEnabled: settings.pushNotificationsEnabled,
      holidays: holidays,
    );
  });
});
