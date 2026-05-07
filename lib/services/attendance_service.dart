import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Auth ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> login(String phone) async {
    try {
      final snap = await _db
          .collection('members')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return {'memberId': doc.id, 'name': doc['name'], 'gymId': doc['gymId']};
    } catch (_) { return null; }
  }

  static Future<void> logout() async { await _auth.signOut(); }

  static Future<Map<String, dynamic>?> register({
    required String name,
    required String phone,
    required String emergencyContact,
    required String membershipType,
    required String gender,
    required DateTime dateOfBirth,
    required String gymId,
    required String aadhaarNumber,
    required String aadhaarName,
  }) async {
    try {
      // Check phone not already registered
      final existing = await _db
          .collection('members')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return {'error': 'Phone already registered.'};

      final ref = await _db.collection('members').add({
        'name':               name,
        'phone':              phone,
        'emergencyContact':   emergencyContact,
        'membershipType':     membershipType,
        'gender':             gender,
        'dateOfBirth':        dateOfBirth.toIso8601String(),
        'gymId':              gymId,
        'fcmToken':           '',
        'createdAt':          FieldValue.serverTimestamp(),
        'active':             true,
        'verificationStatus': 'pending',
        'aadhaarNumber':      aadhaarNumber,
        'aadhaarName':        aadhaarName,
      });
      return {'memberId': ref.id, 'name': name, 'gymId': gymId};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Member ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getMember(String memberId) async {
    try {
      final doc = await _db.collection('members').doc(memberId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) { return null; }
  }

  // ── Gym ──────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getGym(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) { return null; }
  }

  static Future<bool> updateGymLocation(String gymId, double lat, double lng) async {
    try {
      await _db.collection('gyms').doc(gymId).update({
        'latitude':  lat,
        'longitude': lng,
      });
      return true;
    } catch (_) { return false; }
  }

  // ── Auto Attendance ───────────────────────────────────────────────────────────

  static Future<String?> checkIn(String memberId, String gymId) async {
    try {
      final open = await _db
          .collection('attendance')
          .where('memberId', isEqualTo: memberId)
          .where('checkedOut', isNull: true)
          .limit(1)
          .get();
      if (open.docs.isNotEmpty) return open.docs.first.id;

      final ref = await _db.collection('attendance').add({
        'memberId':   memberId,
        'gymId':      gymId,
        'checkedIn':  FieldValue.serverTimestamp(),
        'checkedOut': null,
        'source':     'auto',
        'workoutType': '',
        'notes':      '',
      });
      return ref.id;
    } catch (_) { return null; }
  }

  static Future<void> checkOut(String sessionId) async {
    try {
      await _db.collection('attendance').doc(sessionId).update({
        'checkedOut': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Manual Attendance Form ────────────────────────────────────────────────────

  static Future<String?> manualCheckIn({
    required String memberId,
    required String gymId,
    required String workoutType,
    required String notes,
    required DateTime checkedIn,
  }) async {
    try {
      // Guard: no duplicate open session
      final open = await _db
          .collection('attendance')
          .where('memberId', isEqualTo: memberId)
          .where('checkedOut', isNull: true)
          .limit(1)
          .get();
      if (open.docs.isNotEmpty) return null;

      final ref = await _db.collection('attendance').add({
        'memberId':    memberId,
        'gymId':       gymId,
        'checkedIn':   Timestamp.fromDate(checkedIn),
        'checkedOut':  null,
        'source':      'manual',
        'workoutType': workoutType,
        'notes':       notes,
      });
      return ref.id;
    } catch (_) { return null; }
  }

  static Future<bool> updateAttendanceForm({
    required String sessionId,
    required String workoutType,
    required String notes,
    DateTime? checkedOut,
  }) async {
    try {
      await _db.collection('attendance').doc(sessionId).update({
        'workoutType': workoutType,
        'notes':       notes,
        if (checkedOut != null) 'checkedOut': Timestamp.fromDate(checkedOut),
      });
      return true;
    } catch (_) { return false; }
  }

  static Future<bool> deleteAttendance(String sessionId) async {
    try {
      await _db.collection('attendance').doc(sessionId).delete();
      return true;
    } catch (_) { return false; }
  }

  // ── Notifications ─────────────────────────────────────────────────────────────

  static Future<void> notifyExit(String memberId) async {
    try {
      await _db.collection('exit_requests').add({
        'memberId':    memberId,
        'requestedAt': FieldValue.serverTimestamp(),
        'handled':     false,
      });
    } catch (_) {}
  }

  static Future<void> updateFcmToken(String memberId, String token) async {
    try {
      await _db.collection('members').doc(memberId).update({'fcmToken': token});
    } catch (_) {}
  }

  static Future<bool> submitFeedback({
    required String memberId,
    required String gymId,
    required String message,
    required String category,
  }) async {
    try {
      await _db.collection('feedback').add({
        'memberId':  memberId,
        'gymId':     gymId,
        'message':   message,
        'category':  category,
        'resolved':  false,
        'adminNote': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) { return false; }
  }

  static Future<bool> updateProfile({
    required String memberId,
    required String name,
    required String emergencyContact,
    required String membershipType,
  }) async {
    try {
      await _db.collection('members').doc(memberId).update({
        'name':             name,
        'emergencyContact': emergencyContact,
        'membershipType':   membershipType,
      });
      return true;
    } catch (_) { return false; }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats(String memberId) async {
    try {
      final now   = DateTime.now();
      final week  = now.subtract(const Duration(days: 7));
      final month = DateTime(now.year, now.month, 1);

      final snap = await _db
          .collection('attendance')
          .where('memberId', isEqualTo: memberId)
          .where('checkedIn', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .orderBy('checkedIn', descending: false)
          .get();

      final records = snap.docs.map((d) {
        final data = d.data();
        return AttendanceRecord(
          id:          d.id,
          checkedIn:   (data['checkedIn']  as Timestamp?)?.toDate() ?? now,
          checkedOut:  (data['checkedOut'] as Timestamp?)?.toDate(),
          source:      data['source']      ?? 'auto',
          workoutType: data['workoutType'] ?? '',
          notes:       data['notes']       ?? '',
        );
      }).toList();

      final weekRecords  = records.where((r) => r.checkedIn.isAfter(week)).toList();
      final closedAll    = records.where((r) => !r.isOpen).toList();
      final closedWeek   = weekRecords.where((r) => !r.isOpen).toList();

      final totalMinutes = closedAll.fold<int>(
          0, (s, r) => s + (r.duration?.inMinutes ?? 0));
      final weekMinutes  = closedWeek.fold<int>(
          0, (s, r) => s + (r.duration?.inMinutes ?? 0));

      // Workout type frequency
      final typeCount = <String, int>{};
      for (final r in closedAll) {
        if (r.workoutType != null && r.workoutType!.isNotEmpty) {
          typeCount[r.workoutType!] = (typeCount[r.workoutType!] ?? 0) + 1;
        }
      }
      final topType = typeCount.isEmpty ? '—'
          : typeCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      // Daily visits for last 7 days (index 0 = 6 days ago, index 6 = today)
      final dailyVisits = List<int>.filled(7, 0);
      for (final r in weekRecords) {
        final daysAgo = now.difference(r.checkedIn).inDays;
        if (daysAgo < 7) dailyVisits[6 - daysAgo]++;
      }

      // Streak: consecutive days with at least one visit up to today
      int streak = 0;
      for (int i = 0; i <= 60; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final hasVisit = records.any((r) {
          final d = r.checkedIn;
          return d.year == day.year && d.month == day.month && d.day == day.day;
        });
        if (hasVisit) { streak++; } else { break; }
      }

      return {
        'monthVisits':  records.length,
        'weekVisits':   weekRecords.length,
        'totalMinutes': totalMinutes,
        'weekMinutes':  weekMinutes,
        'avgMinutes':   closedAll.isEmpty ? 0 : totalMinutes ~/ closedAll.length,
        'streak':       streak,
        'topWorkout':   topType,
        'dailyVisits':  dailyVisits,
        'typeCount':    typeCount,
      };
    } catch (_) {
      return {
        'monthVisits': 0, 'weekVisits': 0, 'totalMinutes': 0,
        'weekMinutes': 0, 'avgMinutes': 0, 'streak': 0,
        'topWorkout': '—', 'dailyVisits': List<int>.filled(7, 0),
        'typeCount': <String, int>{},
      };
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────────

  static Stream<List<AttendanceRecord>> historyStream(String memberId) {
    return _db
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .orderBy('checkedIn', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return AttendanceRecord(
                id:          d.id,
                checkedIn:   (data['checkedIn']  as Timestamp?)?.toDate() ?? DateTime.now(),
                checkedOut:  (data['checkedOut'] as Timestamp?)?.toDate(),
                source:      data['source']      ?? 'auto',
                workoutType: data['workoutType'] ?? '',
                notes:       data['notes']       ?? '',
              );
            }).toList());
  }

  static Stream<AttendanceRecord?> openSessionStream(String memberId) {
    return _db
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .where('checkedOut', isNull: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final d    = snap.docs.first;
      final data = d.data();
      return AttendanceRecord(
        id:          d.id,
        checkedIn:   (data['checkedIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
        checkedOut:  null,
        source:      data['source']      ?? 'auto',
        workoutType: data['workoutType'] ?? '',
        notes:       data['notes']       ?? '',
      );
    });
  }
}
