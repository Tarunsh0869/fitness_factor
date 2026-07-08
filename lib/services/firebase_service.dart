import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/attendance_service.dart';

class FirebaseService {
  static String? _memberId;

  static void setMemberId(String id) => _memberId = id;

  static Future<void> init() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _saveToken(token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      debugPrint('[FirebaseService] init failed: $e');
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) return false;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] requestNotificationPermission failed: $e');
      return false;
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      if (_memberId != null) {
        await AttendanceService.updateFcmToken(_memberId!, token);
      }
    } catch (e) {
      debugPrint('[FirebaseService] saveToken failed: $e');
    }
  }

  static Stream<void> exitConfirmationStream() {
    try {
      return FirebaseMessaging.onMessage
          .where((msg) => msg.data['action'] == 'exit_confirmation')
          .map((_) {});
    } catch (_) {
      return const Stream.empty();
    }
  }
}
