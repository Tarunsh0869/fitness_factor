import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _kMemberId = 'memberId';
  static const _kMemberName = 'memberName';
  static const _kGymId = 'gymId';
  static const _kIsAdmin = 'isAdmin';
  static const _kRole = 'role';
  static const _kOnboardingCompleted = 'onboardingCompleted';
  static const roleMember = 'member';
  static const roleGymMaster = 'gym_master';
  static const roleSuperAdmin = 'super_admin';

  static bool isPrivilegedRole(String? role) =>
      role == roleGymMaster || role == roleSuperAdmin;

  static String _normalizeRole(String? role, {required String fallback}) {
    switch (role) {
      case roleMember:
      case roleGymMaster:
      case roleSuperAdmin:
        return role!;
      default:
        return fallback;
    }
  }

  static Future<void> save({
    required String memberId,
    required String memberName,
    required String gymId,
    bool isAdmin = false,
    String? role,
  }) async {
    try {
      final fallbackRole = isAdmin ? roleGymMaster : roleMember;
      final effectiveRole = _normalizeRole(role, fallback: fallbackRole);
      final effectiveIsAdmin = isPrivilegedRole(effectiveRole);
      final p = await SharedPreferences.getInstance();
      await p.setString(_kMemberId, memberId);
      await p.setString(_kMemberName, memberName);
      await p.setString(_kGymId, gymId);
      await p.setBool(_kIsAdmin, effectiveIsAdmin);
      await p.setString(_kRole, effectiveRole);
    } catch (e) {
      debugPrint('[AuthPrefs] save failed: $e');
    }
  }

  static Future<Map<String, dynamic>?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getString(_kMemberId);
      final name = p.getString(_kMemberName);
      final gym = p.getString(_kGymId);
      if (id == null || name == null || gym == null) return null;
      final storedIsAdmin = p.getBool(_kIsAdmin) ?? false;
      final fallbackRole = storedIsAdmin ? roleGymMaster : roleMember;
      final role = _normalizeRole(p.getString(_kRole), fallback: fallbackRole);
      final effectiveIsAdmin = isPrivilegedRole(role);
      return {
        'memberId': id,
        'memberName': name,
        'gymId': gym,
        'isAdmin': effectiveIsAdmin,
        'role': role,
      };
    } catch (e) {
      debugPrint('[AuthPrefs] load failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kMemberId);
      await p.remove(_kMemberName);
      await p.remove(_kGymId);
      await p.remove(_kIsAdmin);
      await p.remove(_kRole);
    } catch (e) {
      debugPrint('[AuthPrefs] clear failed: $e');
    }
  }

  static Future<bool> hasCompletedOnboarding() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_kOnboardingCompleted) ?? false;
    } catch (e) {
      debugPrint('[AuthPrefs] hasCompletedOnboarding failed: $e');
      return false;
    }
  }

  static Future<void> markOnboardingCompleted() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kOnboardingCompleted, true);
    } catch (e) {
      debugPrint('[AuthPrefs] markOnboardingCompleted failed: $e');
    }
  }
}
