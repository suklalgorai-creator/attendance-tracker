/// Schema V2 data migration, deterministic merge, and backup validation library.
///
/// Ownership: Core Data Migration & Sync
library;

import 'dart:convert';
import 'dart:math';

import 'date_utils.dart';

part 'data_migration_models.dart';
part 'data_migration_migrator.dart';
part 'data_migration_backup.dart';

// ==========================================
// DATA MIGRATION - Global Schema Constants
// ==========================================

const int currentSchemaVersion = 2;
const String dailySubjectId = '__daily__';
