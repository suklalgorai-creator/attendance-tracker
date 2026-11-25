import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared navigation drawer and desktop sidebar utility actions:
/// What's New dialog, Support dialog, Feedback email launcher, and App Share.
///
/// Ownership: Shared Shell Navigation
// ==========================================
// SHELL ACTIONS - About, Support & Feedback
// Consolidates shared action handlers used by both AppDrawer and DesktopSidebar.
// ==========================================

/// Displays the "What's New in v2.0" release highlights dialog.
void showWhatsNewDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("What's New in v2.0"),
      content: const Text(
        "⚡ DailyFlow Planning, Focus Timer & Reminders\n"
        "🔐 Google Sign-In & Cloud Firestore Sync\n"
        "📅 Integrated Attendance Register (Holiday-aware)\n"
        "🎨 React-Parity Glassmorphism & Mesh Themes\n"
        "📝 Markdown Sticky Notes & CSV Export",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Displays the "Support the Developer" dialog.
void showSupportDeveloperDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Support the Developer'),
      content: const Text(
        'Thank you for using College Attendance Tracker! If this app helps you, please support us by sharing it with your friends.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Opens the system mail client pre-filled for feedback, falling back to a SnackBar.
Future<void> sendAppFeedback(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final uri = Uri(
    scheme: 'mailto',
    path: 'codecraftdigital.in@gmail.com',
    queryParameters: {'subject': 'Attendance App Feedback'},
  );
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Send feedback to codecraftdigital.in@gmail.com'),
        ),
      );
    }
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Send feedback to codecraftdigital.in@gmail.com'),
      ),
    );
  }
}

/// Triggers the native OS share sheet with an invite message.
void shareAttendanceApp() {
  SharePlus.instance.share(
    ShareParams(
      text: 'I am tracking my college attendance easily with this app!',
      subject: 'College Attendance Tracker',
    ),
  );
}
