import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';

class AdminService {
  static final _db = FirebaseFirestore.instance;
  static FirebaseFirestore get db => _db;

  // â”€â”€ Member name cache (avoids N+1 reads) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static final Map<String, String> _nameCache = {};

  static Future<String> _memberName(String memberId) async {
    if (_nameCache.containsKey(memberId)) return _nameCache[memberId]!;
    try {
      final doc = await _db.collection('members').doc(memberId).get();
      final name = doc.data()?['name'] as String? ?? 'Unknown';
      _nameCache[memberId] = name;
      return name;
    } catch (_) { return 'Unknown'; }
  }

  static void clearNameCache() => _nameCache.clear();

  // â”€â”€ Gym â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<bool> verifyAdminPin(String gymId, String pin) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return false;
      final adminPins = List<String>.from(doc.data()?['adminPins'] ?? []);
      return adminPins.contains(pin);
    } catch (_) { return false; }
  }

  static Future<List<String>> getAdminPins(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['adminPins'] ?? []);
    } catch (_) {
      return [];
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
    List<String>? adminPins,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      };
      if (adminPins != null) {
        data['adminPins'] = adminPins;
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
    } catch (_) { return false; }
  }

  /// Verification: pending | verified | rejected
  static Future<bool> updateVerificationStatus(
      String memberId, String status) async {
    try {
      await _db.collection('members').doc(memberId).update({
        'verificationStatus': status,
        'verifiedAt': status == 'verified' ? FieldValue.serverTimestamp() : null,
      });
      return true;
    } catch (_) { return false; }
  }

  static Future<bool> deleteMember(String memberId) async {
    try {
      await _db.collection('members').doc(memberId).delete();
      _nameCache.remove(memberId);
      return true;
    } catch (_) { return false; }
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
        final mid  = data['memberId'] as String;
        results.add({
          'sessionId':  d.id,
          'memberId':   mid,
          'memberName': await _memberName(mid),
          'checkedIn':  (data['checkedIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'source':     data['source'] ?? 'auto',
          'workoutType': data['workoutType'] ?? '',
        });
      }
      results.sort((a, b) =>
          (a['checkedIn'] as DateTime).compareTo(b['checkedIn'] as DateTime));
      return results;
    });
  }

  static Stream<List<Map<String, dynamic>>> todayAttendanceStream(String gymId) {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return _db
        .collection('attendance')
        .where('gymId', isEqualTo: gymId)
        .where('checkedIn',
            isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
        .orderBy('checkedIn', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final results = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final mid  = data['memberId'] as String;
        results.add({
          'sessionId':   d.id,
          'memberId':    mid,
          'memberName':  await _memberName(mid),
          'checkedIn':   (data['checkedIn']  as Timestamp?)?.toDate() ?? now,
          'checkedOut':  (data['checkedOut'] as Timestamp?)?.toDate(),
          'source':      data['source']      ?? 'auto',
          'workoutType': data['workoutType'] ?? '',
        });
      }
      return results;
    });
  }

  // â”€â”€ Day-wise attendance with stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getDayAttendance(
      String gymId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end   = start.add(const Duration(days: 1));
    try {
      final snap = await _db
          .collection('attendance')
          .where('gymId', isEqualTo: gymId)
          .where('checkedIn', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('checkedIn', isLessThan: Timestamp.fromDate(end))
          .orderBy('checkedIn', descending: false)
          .get();

      final records = <Map<String, dynamic>>[];
      final hourCounts = List<int>.filled(24, 0);
      int totalMinutes = 0;
      int completedCount = 0;

      for (final d in snap.docs) {
        final data      = d.data();
        final mid       = data['memberId'] as String;
        final checkedIn = (data['checkedIn']  as Timestamp?)?.toDate() ?? start;
        final checkedOut = (data['checkedOut'] as Timestamp?)?.toDate();
        hourCounts[checkedIn.hour]++;
        if (checkedOut != null) {
          totalMinutes += checkedOut.difference(checkedIn).inMinutes;
          completedCount++;
        }
        records.add({
          'sessionId':   d.id,
          'memberId':    mid,
          'memberName':  await _memberName(mid),
          'checkedIn':   checkedIn,
          'checkedOut':  checkedOut,
          'source':      data['source']      ?? 'auto',
          'workoutType': data['workoutType'] ?? '',
        });
      }

      final peakHour = hourCounts.indexOf(
          hourCounts.reduce((a, b) => a > b ? a : b));
      final avgMinutes = completedCount > 0
          ? totalMinutes ~/ completedCount : 0;

      return {
        'records':       records,
        'totalVisits':   records.length,
        'completed':     completedCount,
        'avgMinutes':    avgMinutes,
        'peakHour':      peakHour,
        'hourCounts':    hourCounts,
        'totalMinutes':  totalMinutes,
      };
    } catch (_) {
      return {
        'records': [], 'totalVisits': 0, 'completed': 0,
        'avgMinutes': 0, 'peakHour': 0,
        'hourCounts': List<int>.filled(24, 0), 'totalMinutes': 0,
      };
    }
  }

  // â”€â”€ Member attendance with stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getMemberAttendanceStats(
      String memberId, {int limit = 60}) async {
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
          id:          d.id,
          checkedIn:   (data['checkedIn']  as Timestamp?)?.toDate() ?? DateTime.now(),
          checkedOut:  (data['checkedOut'] as Timestamp?)?.toDate(),
          source:      data['source']      ?? 'auto',
          workoutType: data['workoutType'] ?? '',
          notes:       data['notes']       ?? '',
        );
      }).toList();

      final closed = records.where((r) => !r.isOpen).toList();
      final totalMin = closed.fold<int>(
          0, (s, r) => s + (r.duration?.inMinutes ?? 0));
      final avgMin   = closed.isEmpty ? 0 : totalMin ~/ closed.length;
      final maxMin   = closed.isEmpty ? 0
          : closed.map((r) => r.duration?.inMinutes ?? 0)
              .reduce((a, b) => a > b ? a : b);

      // Last 30 days visit count
      final now      = DateTime.now();
      final month30  = now.subtract(const Duration(days: 30));
      final last30   = records.where((r) => r.checkedIn.isAfter(month30)).length;

      // Streak
      int streak = 0;
      for (int i = 0; i <= 60; i++) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final has = records.any((r) {
          final d = r.checkedIn;
          return d.year == day.year && d.month == day.month && d.day == day.day;
        });
        if (has) { streak++; } else { break; }
      }

      // Workout type breakdown
      final typeCount = <String, int>{};
      for (final r in closed) {
        if (r.workoutType != null && r.workoutType!.isNotEmpty) {
          typeCount[r.workoutType!] = (typeCount[r.workoutType!] ?? 0) + 1;
        }
      }

      return {
        'records':    records,
        'total':      records.length,
        'completed':  closed.length,
        'totalMin':   totalMin,
        'avgMin':     avgMin,
        'maxMin':     maxMin,
        'last30':     last30,
        'streak':     streak,
        'typeCount':  typeCount,
        'lastSeen':   records.isEmpty ? null : records.first.checkedIn,
      };
    } catch (_) {
      return {
        'records': [], 'total': 0, 'completed': 0,
        'totalMin': 0, 'avgMin': 0, 'maxMin': 0,
        'last30': 0, 'streak': 0, 'typeCount': <String, int>{},
        'lastSeen': null,
      };
    }
  }

  // â”€â”€ Gym-wide stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> getGymStats(String gymId) async {
    try {
      final now        = DateTime.now();
      final midnight   = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);
      final weekStart  = now.subtract(const Duration(days: 7));

      final results = await Future.wait([
        _db.collection('members')
            .where('gymId', isEqualTo: gymId).count().get(),
        _db.collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedOut', isNull: true).count().get(),
        _db.collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedIn',
                isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
            .count().get(),
        _db.collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedIn',
                isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .count().get(),
        _db.collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedIn',
                isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .count().get(),
        _db.collection('members')
            .where('gymId', isEqualTo: gymId)
            .where('verificationStatus', isEqualTo: 'pending')
            .count().get(),
        _db.collection('feedback')
            .where('gymId', isEqualTo: gymId)
            .where('resolved', isEqualTo: false)
            .count().get(),
      ]);

      return {
        'totalMembers':   results[0].count ?? 0,
        'insideNow':      results[1].count ?? 0,
        'todayVisits':    results[2].count ?? 0,
        'monthVisits':    results[3].count ?? 0,
        'weekVisits':     results[4].count ?? 0,
        'pendingVerify':  results[5].count ?? 0,
        'openFeedback':   results[6].count ?? 0,
      };
    } catch (_) {
      return {
        'totalMembers': 0, 'insideNow': 0, 'todayVisits': 0,
        'monthVisits': 0, 'weekVisits': 0,
        'pendingVerify': 0, 'openFeedback': 0,
      };
    }
  }

  // â”€â”€ Occupancy (last 7 days daily counts) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<List<int>> getWeeklyOccupancy(String gymId) async {
    try {
      final now    = DateTime.now();
      final counts = List<int>.filled(7, 0);
      for (int i = 6; i >= 0; i--) {
        final day   = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final next  = day.add(const Duration(days: 1));
        final snap  = await _db
            .collection('attendance')
            .where('gymId', isEqualTo: gymId)
            .where('checkedIn',
                isGreaterThanOrEqualTo: Timestamp.fromDate(day))
            .where('checkedIn', isLessThan: Timestamp.fromDate(next))
            .count().get();
        counts[6 - i] = snap.count ?? 0;
      }
      return counts;
    } catch (_) { return List<int>.filled(7, 0); }
  }

  // â”€â”€ Force checkout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> forceCheckout(String sessionId) async {
    try {
      await _db.collection('attendance').doc(sessionId).update({
        'checkedOut': FieldValue.serverTimestamp(),
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
        final mid  = data['memberId'] as String? ?? '';
        results.add({
          'id':        d.id,
          'memberId':  mid,
          'memberName': mid.isNotEmpty ? await _memberName(mid) : 'Anonymous',
          'message':   data['message']  ?? '',
          'category':  data['category'] ?? 'general',
          'resolved':  data['resolved'] ?? false,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'adminNote': data['adminNote'] ?? '',
        });
      }
      return results;
    });
  }

  static Future<bool> resolveFeedback(
      String feedbackId, String adminNote) async {
    try {
      await _db.collection('feedback').doc(feedbackId).update({
        'resolved':   true,
        'adminNote':  adminNote,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) { return false; }
  }

  // â”€â”€ Verification queue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Stream<List<Map<String, dynamic>>> pendingVerificationStream(
      String gymId) {
    return _db
        .collection('members')
        .where('gymId', isEqualTo: gymId)
        .where('verificationStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }
}
