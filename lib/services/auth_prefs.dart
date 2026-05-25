import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _kMemberId   = 'memberId';
  static const _kMemberName = 'memberName';
  static const _kGymId      = 'gymId';
  static const _kIsAdmin    = 'isAdmin';
  static const _kJwtToken   = 'jwtToken';
  static const _kApiMemberId = 'apiMemberId';
  static const _kApiGymId   = 'apiGymId';
  static const _kJwtExpiresAt = 'jwtExpiresAt';

  static Future<void> save({
    required String memberId,
    required String memberName,
    required String gymId,
    bool isAdmin = false,
    String? jwtToken,
    int? apiMemberId,
    int? apiGymId,
    DateTime? jwtExpiresAt,
  }) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kMemberId,   memberId);
      await p.setString(_kMemberName, memberName);
      await p.setString(_kGymId,      gymId);
      await p.setBool(_kIsAdmin,      isAdmin);
      if (jwtToken != null && apiMemberId != null && apiGymId != null) {
        await p.setString(_kJwtToken, jwtToken);
        await p.setInt(_kApiMemberId, apiMemberId);
        await p.setInt(_kApiGymId, apiGymId);
        if (jwtExpiresAt != null) {
          await p.setString(_kJwtExpiresAt, jwtExpiresAt.toIso8601String());
        } else {
          await p.remove(_kJwtExpiresAt);
        }
      } else if (isAdmin) {
        await p.remove(_kJwtToken);
        await p.remove(_kApiMemberId);
        await p.remove(_kApiGymId);
        await p.remove(_kJwtExpiresAt);
      }
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
      final jwtExpiresAtRaw = p.getString(_kJwtExpiresAt);
      if (id == null || name == null || gym == null) return null;
      return {
        'memberId':   id,
        'memberName': name,
        'gymId':      gym,
        'isAdmin':    p.getBool(_kIsAdmin) ?? false,
        'jwtToken':   p.getString(_kJwtToken),
        'apiMemberId': p.getInt(_kApiMemberId),
        'apiGymId':    p.getInt(_kApiGymId),
        'jwtExpiresAt': jwtExpiresAtRaw == null
            ? null
            : DateTime.tryParse(jwtExpiresAtRaw),
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
      await p.remove(_kJwtToken);
      await p.remove(_kApiMemberId);
      await p.remove(_kApiGymId);
      await p.remove(_kJwtExpiresAt);
    } catch (e) {
      debugPrint('[AuthPrefs] clear failed: $e');
    }
  }
}
