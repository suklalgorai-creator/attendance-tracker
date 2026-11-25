import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/providers/dashboard_controller.dart';

/// Shared SnackBar helper displaying attendance feedback with a 4-second Undo action.
///
/// Ownership: Shared UI Feedback Utilities
// ==========================================
// SHARED - Attendance Undo SnackBar
// Displays confirmation text and lets the user revert the latest attendance write.
// ==========================================
void showAttendanceUndoSnackBar(
  BuildContext context,
  WidgetRef ref,
  String message,
) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          ref.read(dashboardControllerProvider.notifier).undoLastAction();
        },
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
