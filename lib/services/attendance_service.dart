import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/basic_gym.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static bool _googleInitialized = false;

  // ── Auth ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> login(String phone) async {
    return {
      'error': 'Use email/password or Google login.',
    };
  }

  static Future<Map<String, dynamic>?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final result = await _memberResultForUser(credential.user);
      if (result == null) {
        await _auth.signOut();
        return {
          'error': 'No member profile found for this account. Please register first.',
        };
      }
      return result;
    } on FirebaseAuthException catch (e) {
      return {'error': _authError(e)};
    } catch (e) {
      return {'error': 'Login failed: $e'};
    }
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return {'error': 'Google sign-in is not supported on this device.'};
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final result = await _memberResultForUser(userCredential.user);
      if (result != null) return result;

      final user = userCredential.user;
      return {
        'needsRegistration': true,
        'email': user?.email ?? googleUser.email,
        'name': user?.displayName ?? googleUser.displayName ?? '',
      };
    } on FirebaseAuthException catch (e) {
      return {'error': _authError(e)};
    } on GoogleSignInException catch (e) {
      return {'error': _googleAuthError(e)};
    } catch (e) {
      return {'error': 'Google sign-in failed: $e'};
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  static Future<Map<String, dynamic>?> register({
    required String email,
    String? password,
    bool useCurrentFirebaseUser = false,
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
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        return {'error': 'Email is required.'};
      }

      final existing = await _db
          .collection('members')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return {'error': 'Phone already registered.'};

      User? user;
      String authProvider = 'password';

      if (useCurrentFirebaseUser) {
        user = _auth.currentUser;
        if (user == null) {
          return {'error': 'Google session expired. Please try Google again.'};
        }
        authProvider = user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'google.com';
      } else {
        final rawPassword = password ?? '';
        if (rawPassword.length < 6) {
          return {'error': 'Password must be at least 6 characters.'};
        }
        final credential = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: rawPassword,
        );
        user = credential.user;
        await user?.updateDisplayName(name);
      }

      if (user == null) return {'error': 'Could not create Firebase user.'};

      final aadhaarDigits = aadhaarNumber.replaceAll(' ', '');
      final aadhaarLast4 = aadhaarDigits.length >= 4
          ? aadhaarDigits.substring(aadhaarDigits.length - 4)
          : '';
      final aadhaarMasked = aadhaarLast4.isEmpty ? '' : 'XXXX XXXX $aadhaarLast4';

      await _db.collection('members').doc(user.uid).set({
        'name':               name,
        'email':              user.email ?? normalizedEmail,
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
        'authUid':            user.uid,
        'authProvider':       authProvider,
        'aadhaarNumber':      aadhaarMasked,
        'aadhaarLast4':       aadhaarLast4,
        'aadhaarMasked':      aadhaarMasked,
        'aadhaarName':        aadhaarName,
      }, SetOptions(merge: false));

      return {
        'memberId': user.uid,
        'name': name,
        'gymId': gymId,
      };
    } on FirebaseAuthException catch (e) {
      return {'error': _authError(e)};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
    _googleInitialized = true;
  }

  static Future<Map<String, dynamic>?> _memberResultForUser(User? user) async {
    if (user == null) return null;
    final doc = await _db.collection('members').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    return {
      'memberId': doc.id,
      'name': data['name'] as String? ?? user.displayName ?? 'Member',
      'gymId': data['gymId'] as String? ?? BasicGymConfig.gymId,
      'email': data['email'] as String? ?? user.email ?? '',
      'phone': data['phone'] as String? ?? '',
    };
  }

  static String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'account-exists-with-different-credential':
        return 'This email already uses another sign-in method.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  static String _googleAuthError(GoogleSignInException e) {
    final message = e.description ?? e.toString();
    if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
        message.contains('serverClientId')) {
      return 'Google sign-in needs Firebase OAuth setup. Add this Android app SHA in Firebase, download the new google-services.json, then rebuild.';
    }
    if (e.code == GoogleSignInExceptionCode.canceled) {
      return 'Google sign-in was cancelled.';
    }
    return 'Google sign-in failed: $message';
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
