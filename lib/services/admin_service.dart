import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/basic_gym.dart';
import '../models/attendance_record.dart';

class AdminService {
  static final _db = FirebaseFirestore.instance;
  static FirebaseFirestore get db => _db;
  static const defaultGymId = BasicGymConfig.gymId;
  static const defaultGymCode = BasicGymConfig.gymCode;

  // â”€â”€ Member name cache (avoids N+1 reads) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static final Map<String, String> _nameCache = {};

  static Future<String> _memberName(String memberId) async {
    if (_nameCache.containsKey(memberId)) return _nameCache[memberId]!;
    try {
      final doc = await _db.collection('members').doc(memberId).get();
      final name = doc.data()?['name'] as String? ?? 'Unknown';
      _nameCache[memberId] = name;
      return name;
    } catch (_) {
      return 'Unknown';
    }
  }

  static void clearNameCache() => _nameCache.clear();

  static DateTime _toDateTime(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback;
  }

  static int _safeDurationMinutes(DateTime checkedIn, DateTime checkedOut) {
    final raw = checkedOut.difference(checkedIn).inMinutes;
    if (raw < 0) return 0;
    return raw.clamp(0, 60 * 20);
  }

  static String _dayKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  // â”€â”€ Gym â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static String normalizeGymId(String gymId) {
    final trimmed = gymId.trim();
    return trimmed.toLowerCase() == BasicGymConfig.gymId
        ? BasicGymConfig.gymId
        : trimmed;
  }

  static Future<String?> resolveGymId(String gymIdOrCode) async {
    final trimmed = gymIdOrCode.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.toLowerCase() == BasicGymConfig.gymId ||
        normalizeGymCode(trimmed) == normalizeGymCode(BasicGymConfig.gymCode)) {
      await ensureDefaultGym();
      return BasicGymConfig.gymId;
    }

    try {
      final direct = await _db.collection('gyms').doc(trimmed).get();
      if (direct.exists) return direct.id;

      final normalizedCode = normalizeGymCode(trimmed);
      final byCode = await _db
          .collection('gyms')
          .where('gymCodeNormalized', isEqualTo: normalizedCode)
          .limit(1)
          .get();
      if (byCode.docs.isNotEmpty) return byCode.docs.first.id;

      final legacyByCode = await _db
          .collection('gyms')
          .where('gymCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();
      if (legacyByCode.docs.isNotEmpty) return legacyByCode.docs.first.id;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String normalizeGymCode(String code) {
    final normalized = code.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String suggestGymCode(String name) {
    final words = name
        .trim()
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return normalizeGymCode(words.first);
    final acronym = normalizeGymCode(words.map((word) => word[0]).join());
    if (acronym.length >= 3) return acronym;
    return normalizeGymCode(words.join());
  }

  static Future<bool> gymCodeExists(String code, {String? exceptGymId}) async {
    final normalized = normalizeGymCode(code);
    if (normalized.isEmpty) return false;
    try {
      final snap = await _db
          .collection('gyms')
          .where('gymCodeNormalized', isEqualTo: normalized)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.id != exceptGymId;

      final legacySnap = await _db
          .collection('gyms')
          .where('gymCode', isEqualTo: normalized)
          .limit(1)
          .get();
      if (legacySnap.docs.isEmpty) return false;
      return legacySnap.docs.first.id != exceptGymId;
    } catch (_) {
      return false;
    }
  }

  static Future<void> ensureDefaultGym() async {
    await _db.collection('gyms').doc(BasicGymConfig.gymId).set({
      'name': BasicGymConfig.name,
      'gymCode': BasicGymConfig.gymCode,
      'gymCodeNormalized': normalizeGymCode(BasicGymConfig.gymCode),
      'latitude': BasicGymConfig.latitude,
      'longitude': BasicGymConfig.longitude,
      'radiusMeters': BasicGymConfig.radiusMeters,
      'gymMasterPin': BasicGymConfig.adminPin,
      'adminPin': BasicGymConfig.adminPin,
      'adminPins': FieldValue.arrayUnion([BasicGymConfig.adminPin]),
    }, SetOptions(merge: true));
  }

  static String? _resolveGymMasterPinFromData(Map<String, dynamic> data) {
    final gymMasterPin = data['gymMasterPin'] as String?;
    if (gymMasterPin != null && gymMasterPin.trim().isNotEmpty) {
      return gymMasterPin.trim();
    }

    final adminPins = List<String>.from(data['adminPins'] ?? []);
    if (adminPins.isNotEmpty) return adminPins.first;

    final legacyAdminPin = data['adminPin'] as String?;
    if (legacyAdminPin != null && legacyAdminPin.trim().isNotEmpty) {
      return legacyAdminPin.trim();
    }

    return null;
  }

  static Future<bool> verifyAdminPin(String gymId, String pin) async {
    try {
      final resolvedGymId = await resolveGymId(gymId);
      if (resolvedGymId == null) return false;

      final doc = await _db.collection('gyms').doc(resolvedGymId).get();
      if (!doc.exists) return false;
      final data = doc.data() ?? {};
      final adminPins = List<String>.from(data['adminPins'] ?? []);
      final legacyAdminPin = data['adminPin'] as String?;
      final gymMasterPin = _resolveGymMasterPinFromData(data);
      return adminPins.contains(pin) ||
          legacyAdminPin == pin ||
          gymMasterPin == pin;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> getAdminPins(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return [];
      final data = doc.data() ?? {};
      final adminPins = List<String>.from(data['adminPins'] ?? []);
      if (adminPins.isNotEmpty) return adminPins;
      final gymMasterPin = _resolveGymMasterPinFromData(data);
      if (gymMasterPin == null) return [];
      return [gymMasterPin];
    } catch (_) {
      return [];
    }
  }

  static Future<String?> getGymMasterPin(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      return _resolveGymMasterPinFromData(data);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> setGymMasterPin(String gymId, String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.length != 4 || int.tryParse(cleanPin) == null) return false;

    try {
      await _db.collection('gyms').doc(gymId).update({
        'gymMasterPin': cleanPin,
        'adminPin': cleanPin,
        'adminPins': [cleanPin],
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addAdminPin(String gymId, String pin) async {
    try {
      final docRef = _db.collection('gyms').doc(gymId);
      await _db.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;
        final adminPins = List<String>.from(doc.data()?['adminPins'] ?? []);
        if (!adminPins.contains(pin)) {
          adminPins.add(pin);
          transaction.update(docRef, {'adminPins': adminPins});
        }
        return true;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeAdminPin(String gymId, String pin) async {
    try {
      final docRef = _db.collection('gyms').doc(gymId);
      await _db.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;
        final adminPins = List<String>.from(doc.data()?['adminPins'] ?? []);
        adminPins.removeWhere((p) => p == pin);
        transaction.update(docRef, {'adminPins': adminPins});
        return true;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getGymDetails(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateGymSettings({
    required String gymId,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String gymCode,
    List<String>? adminPins,
  }) async {
    try {
      final normalizedCode = normalizeGymCode(gymCode);
      if (normalizedCode.isEmpty) return false;
      if (await gymCodeExists(normalizedCode, exceptGymId: gymId)) return false;

      final data = <String, dynamic>{
        'name': name,
        'gymCode': normalizedCode,
        'gymCodeNormalized': normalizedCode,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };
      if (adminPins != null) {
        final sanitizedPins = adminPins
            .map((p) => p.trim())
            .where((p) => p.length == 4 && int.tryParse(p) != null)
            .toList();
        if (sanitizedPins.isNotEmpty) {
          final primaryPin = sanitizedPins.first;
          data['adminPins'] = [primaryPin];
          data['gymMasterPin'] = primaryPin;
          data['adminPin'] = primaryPin;
        }
      }
      await _db.collection('gyms').doc(gymId).update(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  // â”€â”€ Members â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Stream<List<Map<String, dynamic>>> membersStream(String gymId) {
    return _db
        .collection('members')
        .where('gymId', isEqualTo: gymId)
        .orderBy('name')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          // Update name cache
          for (final m in list) {
            _nameCache[m['id'] as String] = m['name'] as String? ?? 'Unknown';
          }
          return list;
        });
  }

  static Future<bool> toggleMemberActive(String memberId, bool active) async {
    try {
      await _db.collection('members').doc(memberId).update({'active': active});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verification: pending | verified | rejected
  static Future<bool> updateVerificationStatus(
    String memberId,
    String status,
  ) async {
    try {
      await _db.collection('members').doc(memberId).update({
        'verificationStatus': status,
        'verifiedAt': status == 'verified'
            ? FieldValue.serverTimestamp()
            : null,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteMember(String memberId) async {
    try {
      await _db.collection('members').doc(memberId).delete();
      _nameCache.remove(memberId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // â”€â”€ Attendance streams â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Stream<List<Map<String, dynamic>>> insideNowStream(String gymId) {
    return _db
        .collection('attendance')
        .where('gymId', isEqualTo: gymId)
        .where('checkedOut', isNull: true)
        .snapshots()
        .asyncMap((snap) async {
          final results = <Map<String, dynamic>>[];
          for (final d in snap.docs) {
            final data = d.data();
            final mid = data['memberId'] as String;
            results.add({
              'sessionId': d.id,
              'memberId': mid,
              'memberName': await _memberName(mid),
              'checkedIn': _toDateTime(
                data['checkedIn'],
                fallback: DateTime.now(),
              ),
              'source': data['source'] ?? 'auto',
              'workoutType': data['workoutType'] ?? '',
              'sessionState': data['sessionState'] ?? 'checked_in',
              'checkInMethod': data['checkInMethod'] ?? 'legacy',
            });
          }
          results.sort(
            (a, b) => (a['checkedIn'] as DateTime).compareTo(
              b['checkedIn'] as DateTime,
            ),
          );
          return results;
        });
  }

  static Stream<List<Map<String, dynamic>>> todayAttendanceStream(
    String gymId,
  ) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return _db
        .collection('attendance')
        .where('gymId', isEqualTo: gymId)
        .where(
          'checkedIn',
          isGreaterThanOrEqualTo: Timestamp.fromDate(midnight),
        )
        .orderBy('checkedIn', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final results = <Map<String, dynamic>>[];
          for (final d in snap.docs) {
            final data = d.data();
            final mid = data['memberId'] as String;
            results.add({
              'sessionId': d.id,
              'memberId': mid,
              'memberName': await _memberName(mid),
              'checkedIn': _toDateTime(data['checkedIn'], fallback: now),
              'checkedOut': data['checkedOut'] == null
                  ? null
                  : _toDateTime(data['checkedOut'], fallback: now),
              'source': data['source'] ?? 'auto',
              'workoutType': data['workoutType'] ?? '',
              'sessionState': data['sessionState'] ?? 'legacy',
              'checkInMethod': data['checkInMethod'] ?? 'legacy',
            });
          }
          return results;
        });
  }

  // â”€â”€ Day-wise attendance with stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getDayAttendance(
    String gymId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final start7 = end.subtract(const Duration(days: 7));
    final start30 = end.subtract(const Duration(days: 30));
    try {
      final snap = await _db
          .collection('attendance')
          .where('gymId', isEqualTo: gymId)
          .where(
            'checkedIn',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start.toUtc()),
          )
          .where('checkedIn', isLessThan: Timestamp.fromDate(end.toUtc()))
          .orderBy('checkedIn', descending: false)
          .get();

      final last30Snap = await _db
          .collection('attendance')
          .where('gymId', isEqualTo: gymId)
          .where(
            'checkedIn',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start30.toUtc()),
          )
          .where('checkedIn', isLessThan: Timestamp.fromDate(end.toUtc()))
          .orderBy('checkedIn', descending: false)
          .get();

      final records = <Map<String, dynamic>>[];
      final hourCounts = List<int>.filled(24, 0);
      int totalMinutes = 0;
      int completedCount = 0;
      final uniqueMembers = <String>{};

      for (final d in snap.docs) {
        final data = d.data();
        final mid = data['memberId'] as String;
        uniqueMembers.add(mid);
        final checkedIn = _toDateTime(data['checkedIn'], fallback: start);
        final checkedOut = data['checkedOut'] == null
            ? null
            : _toDateTime(data['checkedOut'], fallback: checkedIn);
        hourCounts[checkedIn.hour]++;
        if (checkedOut != null) {
          totalMinutes += _safeDurationMinutes(checkedIn, checkedOut);
          completedCount++;
        }
        records.add({
          'sessionId': d.id,
          'memberId': mid,
          'memberName': await _memberName(mid),
          'checkedIn': checkedIn,
          'checkedOut': checkedOut,
          'source': data['source'] ?? 'auto',
          'workoutType': data['workoutType'] ?? '',
          'sessionState': data['sessionState'] ?? 'legacy',
          'checkInMethod': data['checkInMethod'] ?? 'legacy',
        });
      }

      final peakHour = hourCounts.indexOf(
        hourCounts.reduce((a, b) => a > b ? a : b),
      );
      final avgMinutes = completedCount > 0
          ? totalMinutes ~/ completedCount
          : 0;
      final openSessions = records.length - completedCount;
      final missedCheckoutRate = records.isEmpty
          ? 0.0
          : openSessions / records.length;

      final visits7ByMember = <String, int>{};
      final visits30ByMember = <String, int>{};
      for (final d in last30Snap.docs) {
        final data = d.data();
        final mid = data['memberId'] as String? ?? '';
        if (mid.isEmpty) continue;
        final checkedIn = _toDateTime(data['checkedIn'], fallback: start30);
        visits30ByMember[mid] = (visits30ByMember[mid] ?? 0) + 1;
        if (!checkedIn.isBefore(start7)) {
          visits7ByMember[mid] = (visits7ByMember[mid] ?? 0) + 1;
        }
      }

      final repeatMembers7d = visits7ByMember.values
          .where((c) => c >= 2)
          .length;
      final repeatMembers30d = visits30ByMember.values
          .where((c) => c >= 4)
          .length;

      return {
        'records': records,
        'totalVisits': records.length,
        'uniqueAttendees': uniqueMembers.length,
        'completed': completedCount,
        'openSessions': openSessions,
        'missedCheckoutRate': missedCheckoutRate,
        'avgMinutes': avgMinutes,
        'peakHour': peakHour,
        'repeatMembers7d': repeatMembers7d,
        'repeatMembers30d': repeatMembers30d,
        'hourCounts': hourCounts,
        'totalMinutes': totalMinutes,
      };
    } catch (_) {
      return {
        'records': [],
        'totalVisits': 0,
        'uniqueAttendees': 0,
        'completed': 0,
        'openSessions': 0,
        'missedCheckoutRate': 0.0,
        'avgMinutes': 0,
        'peakHour': 0,
        'repeatMembers7d': 0,
        'repeatMembers30d': 0,
        'hourCounts': List<int>.filled(24, 0),
        'totalMinutes': 0,
      };
    }
  }

  // â”€â”€ Member attendance with stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getMemberAttendanceStats(
    String memberId, {
    int limit = 60,
  }) async {
    try {
      final snap = await _db
          .collection('attendance')
          .where('memberId', isEqualTo: memberId)
          .orderBy('checkedIn', descending: true)
          .limit(limit)
          .get();

      final records = snap.docs.map((d) {
        final data = d.data();
        return AttendanceRecord(
          id: d.id,
          checkedIn:
              (data['checkedIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
          checkedOut: (data['checkedOut'] as Timestamp?)?.toDate(),
          source: data['source'] ?? 'auto',
          workoutType: data['workoutType'] ?? '',
          notes: data['notes'] ?? '',
        );
      }).toList();

      final closed = records.where((r) => !r.isOpen).toList();
      final open = records.where((r) => r.isOpen).toList();
      final totalMin = closed.fold<int>(
        0,
        (s, r) => s + _safeDurationMinutes(r.checkedIn, r.checkedOut!),
      );
      final avgMin = closed.isEmpty ? 0 : totalMin ~/ closed.length;
      final maxMin = closed.isEmpty
          ? 0
          : closed
                .map((r) => _safeDurationMinutes(r.checkedIn, r.checkedOut!))
                .reduce((a, b) => a > b ? a : b);

      // Last 30 days visit count
      final now = DateTime.now();
      final month30 = now.subtract(const Duration(days: 30));
      final last30 = records.where((r) => r.checkedIn.isAfter(month30)).length;

      // Streak
      int streak = 0;
      for (int i = 0; i <= 60; i++) {
        final day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final has = records.any((r) {
          final d = r.checkedIn;
          return d.year == day.year && d.month == day.month && d.day == day.day;
        });
        if (has) {
          streak++;
        } else {
          break;
        }
      }

      // Workout type breakdown
      final typeCount = <String, int>{};
      for (final r in closed) {
        if (r.workoutType != null && r.workoutType!.isNotEmpty) {
          typeCount[r.workoutType!] = (typeCount[r.workoutType!] ?? 0) + 1;
        }
      }
      final missedCheckoutRate = records.isEmpty
          ? 0.0
          : open.length / records.length;

      return {
        'records': records,
        'total': records.length,
        'completed': closed.length,
        'openSessions': open.length,
        'missedCheckoutRate': missedCheckoutRate,
        'totalMin': totalMin,
        'avgMin': avgMin,
        'maxMin': maxMin,
        'last30': last30,
        'streak': streak,
        'typeCount': typeCount,
        'lastSeen': records.isEmpty ? null : records.first.checkedIn,
      };
    } catch (_) {
      return {
        'records': [],
        'total': 0,
        'completed': 0,
        'openSessions': 0,
        'missedCheckoutRate': 0.0,
        'totalMin': 0,
        'avgMin': 0,
        'maxMin': 0,
        'last30': 0,
        'streak': 0,
        'typeCount': <String, int>{},
        'lastSeen': null,
      };
    }
  }

  // â”€â”€ Gym-wide stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getGymStats(String gymId) async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final tomorrow = midnight.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final weekStart = now.subtract(const Duration(days: 7));
      final start7 = tomorrow.subtract(const Duration(days: 7));
      final start30 = tomorrow.subtract(const Duration(days: 30));

      final results = await Future.wait([
        _db
            .collection('members')
            .where('gymId', isEqualTo: gymId)
            .count()
            .get(),
        _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedOut', isNull: true)
            .count()
            .get(),
        _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where(
              'checkedIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(midnight),
            )
            .count()
            .get(),
        _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where(
              'checkedIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
            )
            .count()
            .get(),
        _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where(
              'checkedIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
            )
            .count()
            .get(),
        _db
            .collection('members')
            .where('gymId', isEqualTo: gymId)
            .where('verificationStatus', isEqualTo: 'pending')
            .count()
            .get(),
        _db
            .collection('feedback')
            .where('gymId', isEqualTo: gymId)
            .where('resolved', isEqualTo: false)
            .count()
            .get(),
        _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where(
              'checkedIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(midnight.toUtc()),
            )
            .where(
              'checkedIn',
              isLessThan: Timestamp.fromDate(tomorrow.toUtc()),
            )
            .get(),
        _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where(
              'checkedIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start30.toUtc()),
            )
            .where(
              'checkedIn',
              isLessThan: Timestamp.fromDate(tomorrow.toUtc()),
            )
            .get(),
      ]);

      final todaySnap = results[7] as QuerySnapshot<Map<String, dynamic>>;
      final last30Snap = results[8] as QuerySnapshot<Map<String, dynamic>>;
      final uniqueTodayMembers = <String>{};
      int completedToday = 0;
      for (final d in todaySnap.docs) {
        final data = d.data();
        final mid = data['memberId'] as String? ?? '';
        if (mid.isNotEmpty) uniqueTodayMembers.add(mid);
        if (data['checkedOut'] != null) completedToday++;
      }
      final todayRecordCount = todaySnap.docs.length;
      final missedCheckoutRateToday = todayRecordCount == 0
          ? 0.0
          : (todayRecordCount - completedToday) / todayRecordCount;

      final visits7ByMember = <String, int>{};
      final visits30ByMember = <String, int>{};
      for (final d in last30Snap.docs) {
        final data = d.data();
        final mid = data['memberId'] as String? ?? '';
        if (mid.isEmpty) continue;
        final checkedIn = _toDateTime(data['checkedIn'], fallback: start30);
        visits30ByMember[mid] = (visits30ByMember[mid] ?? 0) + 1;
        if (!checkedIn.isBefore(start7)) {
          visits7ByMember[mid] = (visits7ByMember[mid] ?? 0) + 1;
        }
      }
      final repeatMembers7d = visits7ByMember.values
          .where((c) => c >= 2)
          .length;
      final repeatMembers30d = visits30ByMember.values
          .where((c) => c >= 4)
          .length;

      final totalMembers =
          (((results[0] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;
      final insideNow =
          (((results[1] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;
      final todayVisits =
          (((results[2] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;
      final monthVisits =
          (((results[3] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;
      final weekVisits =
          (((results[4] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;
      final pendingVerify =
          (((results[5] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;
      final openFeedback =
          (((results[6] as AggregateQuerySnapshot).count) as num?)?.toInt() ??
          0;

      return {
        'totalMembers': totalMembers,
        'insideNow': insideNow,
        'todayVisits': todayVisits,
        'monthVisits': monthVisits,
        'weekVisits': weekVisits,
        'pendingVerify': pendingVerify,
        'openFeedback': openFeedback,
        'uniqueAttendeesToday': uniqueTodayMembers.length,
        'missedCheckoutRateToday': missedCheckoutRateToday,
        'repeatMembers7d': repeatMembers7d,
        'repeatMembers30d': repeatMembers30d,
      };
    } catch (_) {
      return {
        'totalMembers': 0,
        'insideNow': 0,
        'todayVisits': 0,
        'monthVisits': 0,
        'weekVisits': 0,
        'pendingVerify': 0,
        'openFeedback': 0,
        'uniqueAttendeesToday': 0,
        'missedCheckoutRateToday': 0.0,
        'repeatMembers7d': 0,
        'repeatMembers30d': 0,
      };
    }
  }

  // â”€â”€ Occupancy (last 7 days daily counts) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<int>> getWeeklyOccupancy(String gymId) async {
    try {
      final now = DateTime.now();
      final counts = List<int>.filled(7, 0);
      for (int i = 6; i >= 0; i--) {
        final day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final next = day.add(const Duration(days: 1));
        final snap = await _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedIn', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
            .where('checkedIn', isLessThan: Timestamp.fromDate(next))
            .count()
            .get();
        counts[6 - i] = snap.count ?? 0;
      }
      return counts;
    } catch (_) {
      return List<int>.filled(7, 0);
    }
  }

  // â”€â”€ Force checkout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<Map<String, dynamic>>> getMemberAttendanceInsights(
    String gymId, {
    int lookbackDays = 30,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final safeLookback = lookbackDays < 7 ? 7 : lookbackDays;
    final startLookback = today.subtract(Duration(days: safeLookback - 1));
    final start7 = today.subtract(const Duration(days: 6));

    try {
      final membersSnap = await _db
          .collection('members')
          .where('gymId', isEqualTo: gymId)
          .get();

      if (membersSnap.docs.isEmpty) {
        return const <Map<String, dynamic>>[];
      }

      final summaries = <String, Map<String, dynamic>>{};
      for (final doc in membersSnap.docs) {
        final data = doc.data();
        summaries[doc.id] = {
          'id': doc.id,
          'name': data['name'] as String? ?? 'Member',
          'phone': data['phone'] as String? ?? '',
          'membershipType': data['membershipType'] as String? ?? 'Basic',
          'active': data['active'] as bool? ?? true,
          'verificationStatus':
              data['verificationStatus'] as String? ?? 'pending',
          'visits7': 0,
          'visits30': 0,
          'totalMinutes30': 0,
          'avgMinutes30': 0,
          'openSession': false,
          'lastSeen': null,
          'streakDays': 0,
        };
      }

      final attendanceSnap = await _db
          .collection('attendance')
          .where('gymId', isEqualTo: gymId)
          .where(
            'checkedIn',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startLookback.toUtc()),
          )
          .orderBy('checkedIn', descending: true)
          .get();

      final daysByMember = <String, Set<String>>{};
      final completedByMember = <String, int>{};

      for (final doc in attendanceSnap.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String? ?? '';
        if (memberId.isEmpty) continue;
        final summary = summaries[memberId];
        if (summary == null) continue;

        final checkedIn = _toDateTime(data['checkedIn'], fallback: now);
        final checkedOut = data['checkedOut'] == null
            ? null
            : _toDateTime(data['checkedOut'], fallback: checkedIn);

        summary['visits30'] = (summary['visits30'] as int) + 1;
        if (!checkedIn.isBefore(start7)) {
          summary['visits7'] = (summary['visits7'] as int) + 1;
        }

        if (summary['lastSeen'] == null ||
            (summary['lastSeen'] as DateTime).isBefore(checkedIn)) {
          summary['lastSeen'] = checkedIn;
        }

        daysByMember
            .putIfAbsent(memberId, () => <String>{})
            .add(_dayKey(checkedIn));

        if (checkedOut == null) {
          summary['openSession'] = true;
          continue;
        }

        final minutes = _safeDurationMinutes(checkedIn, checkedOut);
        summary['totalMinutes30'] =
            (summary['totalMinutes30'] as int) + minutes;
        completedByMember[memberId] = (completedByMember[memberId] ?? 0) + 1;
      }

      for (final entry in summaries.entries) {
        final memberId = entry.key;
        final summary = entry.value;

        final completedSessions = completedByMember[memberId] ?? 0;
        final totalMinutes = summary['totalMinutes30'] as int;
        summary['avgMinutes30'] = completedSessions == 0
            ? 0
            : totalMinutes ~/ completedSessions;

        final daySet = daysByMember[memberId] ?? const <String>{};
        var streak = 0;
        for (var i = 0; i < safeLookback; i++) {
          final day = today.subtract(Duration(days: i));
          if (daySet.contains(_dayKey(day))) {
            streak++;
          } else {
            break;
          }
        }
        summary['streakDays'] = streak;
      }

      final list = summaries.values.toList();
      list.sort((a, b) {
        final byVisits30 = (b['visits30'] as int).compareTo(
          a['visits30'] as int,
        );
        if (byVisits30 != 0) return byVisits30;
        final byVisits7 = (b['visits7'] as int).compareTo(a['visits7'] as int);
        if (byVisits7 != 0) return byVisits7;
        final aLast = a['lastSeen'] as DateTime?;
        final bLast = b['lastSeen'] as DateTime?;
        if (aLast == null && bLast == null) return 0;
        if (aLast == null) return 1;
        if (bLast == null) return -1;
        return bLast.compareTo(aLast);
      });
      return list;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Future<void> forceCheckout(String sessionId) async {
    try {
      final ref = _db.collection('attendance').doc(sessionId);
      final checkedOutUtc = DateTime.now().toUtc();
      await ref.update({
        'checkedOut': Timestamp.fromDate(checkedOutUtc),
        'checkedOutServerAt': FieldValue.serverTimestamp(),
        'sessionState': 'force_checked_out',
        'checkoutReason': 'force',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await ref.collection('auditLogs').add({
        'event': 'force_checkout',
        'actor': 'admin',
        'payload': {'checkedOutUtc': checkedOutUtc.toIso8601String()},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // â”€â”€ Feedback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Stream<List<Map<String, dynamic>>> feedbackStream(String gymId) {
    return _db
        .collection('feedback')
        .where('gymId', isEqualTo: gymId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snap) async {
          final results = <Map<String, dynamic>>[];
          for (final d in snap.docs) {
            final data = d.data();
            final mid = data['memberId'] as String? ?? '';
            results.add({
              'id': d.id,
              'memberId': mid,
              'memberName': mid.isNotEmpty
                  ? await _memberName(mid)
                  : 'Anonymous',
              'message': data['message'] ?? '',
              'category': data['category'] ?? 'general',
              'resolved': data['resolved'] ?? false,
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              'adminNote': data['adminNote'] ?? '',
            });
          }
          return results;
        });
  }

  static Future<bool> resolveFeedback(
    String feedbackId,
    String adminNote,
  ) async {
    try {
      await _db.collection('feedback').doc(feedbackId).update({
        'resolved': true,
        'adminNote': adminNote,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // â”€â”€ Verification queue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Stream<List<Map<String, dynamic>>> pendingVerificationStream(
    String gymId,
  ) {
    return _db
        .collection('members')
        .where('gymId', isEqualTo: gymId)
        .where('verificationStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }
}
