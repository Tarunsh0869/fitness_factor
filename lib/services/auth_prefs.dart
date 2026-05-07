import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _kMemberId   = 'memberId';
  static const _kMemberName = 'memberName';
  static const _kGymId      = 'gymId';
  static const _kIsAdmin    = 'isAdmin';

  static Future<void> save({
    required String memberId,
    required String memberName,
    required String gymId,
    bool isAdmin = false,
  }) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kMemberId,   memberId);
      await p.setString(_kMemberName, memberName);
      await p.setString(_kGymId,      gymId);
      await p.setBool(_kIsAdmin,      isAdmin);
    } catch (e) {
      debugPrint('[AuthPrefs] save failed: $e');
    }
  }

  static Future<Map<String, dynamic>?> load() async {
    try {
      final p    = await SharedPreferences.getInstance();
      final id   = p.getString(_kMemberId);
      final name = p.getString(_kMemberName);
      final gym  = p.getString(_kGymId);
      if (id == null || name == null || gym == null) return null;
      return {
        'memberId':   id,
        'memberName': name,
        'gymId':      gym,
        'isAdmin':    p.getBool(_kIsAdmin) ?? false,
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
    } catch (e) {
      debugPrint('[AuthPrefs] clear failed: $e');
    }
  }
}
