import 'package:shared_preferences/shared_preferences.dart';

class GuestSessionService {
  static const _kActive = 'guest.active';
  static const _kMeaningfulActionCount = 'guest.meaningfulActionCount';
  static const _kStarterWorkoutsCompleted = 'guest.starterWorkoutsCompleted';
  static const _kLastAction = 'guest.lastAction';

  static Future<void> startSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kActive, true);
  }

  static Future<void> recordMeaningfulAction(String action) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kMeaningfulActionCount) ?? 0;
    await prefs.setInt(_kMeaningfulActionCount, current + 1);
    await prefs.setString(_kLastAction, action);
    await prefs.setBool(_kActive, true);
  }

  static Future<void> recordStarterWorkoutComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kStarterWorkoutsCompleted) ?? 0;
    await prefs.setInt(_kStarterWorkoutsCompleted, current + 1);
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'active': prefs.getBool(_kActive) ?? false,
      'meaningfulActionCount': prefs.getInt(_kMeaningfulActionCount) ?? 0,
      'starterWorkoutsCompleted': prefs.getInt(_kStarterWorkoutsCompleted) ?? 0,
      'lastAction': prefs.getString(_kLastAction) ?? '',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActive);
    await prefs.remove(_kMeaningfulActionCount);
    await prefs.remove(_kStarterWorkoutsCompleted);
    await prefs.remove(_kLastAction);
  }
}
