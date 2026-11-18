import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/auth_user_model.dart';

/// Contract for persisting authentication state and guest sessions in local Hive storage.
abstract class AuthLocalDataSource {
  Future<AuthUserModel?> getSavedUser();
  Future<void> saveUser(AuthUserModel user);
  Future<void> clearUser();
  Future<bool> isGuestMode();
  Future<void> setGuestMode(bool isGuest);
  Future<bool> isOnboardingComplete();
  Future<void> setOnboardingComplete(bool complete);

  // Synchronous cached accessors to eliminate screen flashes on bootstrap
  AuthUserModel? getSavedUserSync();
  bool isGuestModeSync();
  bool isOnboardingCompleteSync();
}

/// Hive implementation of [AuthLocalDataSource] backed by `settings_box`.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String authUserKey = 'auth_user';
  static const String guestModeKey = 'guest_mode';
  static const String onboardingCompletedKey = 'onboarding_completed';

  final Box? _customBox;

  AuthLocalDataSourceImpl({Box? box}) : _customBox = box;

  Box? get _box {
    if (_customBox != null) return _customBox;
    if (DatabaseService.isBoxOpen(DatabaseService.settingsBoxName)) {
      return DatabaseService.getBox(DatabaseService.settingsBoxName);
    }
    return null;
  }

  @override
  AuthUserModel? getSavedUserSync() {
    try {
      final box = _box;
      if (box == null) return null;
      final raw = box.get(authUserKey);
      if (raw is Map) {
        return AuthUserModel.fromMap(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  bool isGuestModeSync() {
    try {
      final box = _box;
      if (box == null) return false;
      final raw = box.get(guestModeKey);
      if (raw is bool) {
        return raw;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  bool isOnboardingCompleteSync() {
    try {
      final box = _box;
      if (box == null) return false;

      final explicitFlag = box.get(onboardingCompletedKey);
      if (explicitFlag == true) {
        return true;
      }

      final settingsRaw = box.get('user_settings');
      if (settingsRaw is Map) {
        final startDate = settingsRaw['startDate']?.toString().trim();
        if (startDate != null && startDate.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AuthUserModel?> getSavedUser() async {
    try {
      return getSavedUserSync();
    } catch (e) {
      throw CacheException('Failed to load saved auth user: $e');
    }
  }

  @override
  Future<void> saveUser(AuthUserModel user) async {
    try {
      final box = _box;
      if (box != null) {
        await box.put(authUserKey, user.toMap());
      }
    } catch (e) {
      throw CacheException('Failed to save auth user: $e');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      final box = _box;
      if (box != null) {
        await box.delete(authUserKey);
        await box.put(guestModeKey, false);
      }
    } catch (e) {
      throw CacheException('Failed to clear auth user: $e');
    }
  }

  @override
  Future<bool> isGuestMode() async {
    try {
      return isGuestModeSync();
    } catch (e) {
      throw CacheException('Failed to read guest mode flag: $e');
    }
  }

  @override
  Future<void> setGuestMode(bool isGuest) async {
    try {
      final box = _box;
      if (box != null) {
        await box.put(guestModeKey, isGuest);
      }
    } catch (e) {
      throw CacheException('Failed to persist guest mode flag: $e');
    }
  }

  @override
  Future<bool> isOnboardingComplete() async {
    try {
      return isOnboardingCompleteSync();
    } catch (e) {
      throw CacheException('Failed to verify onboarding completion: $e');
    }
  }

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    try {
      final box = _box;
      if (box != null) {
        await box.put(onboardingCompletedKey, complete);
      }
    } catch (e) {
      throw CacheException('Failed to persist onboarding status: $e');
    }
  }
}
