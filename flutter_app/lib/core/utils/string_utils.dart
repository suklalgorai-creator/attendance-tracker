/// Shared string formatting utilities used across onboarding and settings.
///
/// Ownership: Core Utilities
library;

// ==========================================
// CORE UTILS - String Formatting
// ==========================================

/// Converts [input] to title case by capitalizing the first letter of each
/// whitespace-delimited word while preserving interior characters.
String toTitleCase(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  return trimmed
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) =>
            word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : ''),
      )
      .join(' ');
}
