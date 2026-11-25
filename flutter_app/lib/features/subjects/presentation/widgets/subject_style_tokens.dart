import 'package:flutter/material.dart';

/// Design palette and curated academic icons shared across subject configuration and analytics.
///
/// Ownership: Subjects Feature
// ==========================================
// SUBJECTS - Style Tokens & Curated Icons
// ==========================================

/// Available curated subject colors matching design tokens.
const List<String> kSubjectColors = [
  '#10B981', // Emerald
  '#F43F5E', // Rose
  '#F59E0B', // Amber
  '#3B82F6', // Blue
  '#8B5CF6', // Purple
  '#6366F1', // Indigo
  '#14B8A6', // Teal
  '#06B6D4', // Cyan
  '#F97316', // Orange
  '#EC4899', // Pink
  '#64748B', // Slate
];

/// Curated academic icons keyed by persistent string identifier.
const Map<String, IconData> kAcademicIcons = {
  'school': Icons.school_rounded,
  'book': Icons.menu_book_rounded,
  'computer': Icons.computer_rounded,
  'calculate': Icons.calculate_rounded,
  'science': Icons.science_rounded,
  'history_edu': Icons.history_edu_rounded,
  'palette': Icons.palette_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'language': Icons.language_rounded,
  'insights': Icons.insights_rounded,
};
