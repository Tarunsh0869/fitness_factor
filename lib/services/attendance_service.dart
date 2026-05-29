import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/basic_gym.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static bool _googleInitialized = false;
  static const _sessionStateCheckedIn = 'checked_in';
  static const _sessionStateCheckedOut = 'checked_out';
  static const _sessionStateAutoClosed = 'auto_closed';
  static const _sessionStateForceCheckedOut = 'force_checked_out';

  // ── Auth ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> login(String phone) async {
    return {'error': 'Use email/password or Google login.'};
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
          'error':
              'No member profile found for this account. Please register first.',
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
    String? displayName,
    String? gymId,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        return {'error': 'Email is required.'};
      }

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
      }

      if (user == null) return {'error': 'Could not create Firebase user.'};
      final resolvedGymId = await _resolveRegistrationGymId(gymId);
      final fallbackName = _nameFromEmail(user.email ?? normalizedEmail);
      final name = (displayName ?? user.displayName ?? fallbackName).trim();
      await user.updateDisplayName(name);

      await _db.collection('members').doc(user.uid).set({
        'name': name,
        'email': user.email ?? normalizedEmail,
        'phone': '',
        'emergencyContact': '',
        'membershipType': 'Free',
        'gender': '',
        'dateOfBirth': null,
        'gymId': resolvedGymId,
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'verificationStatus': 'pending',
        'authUid': user.uid,
        'authProvider': authProvider,
        'goal': '',
        'activityLevel': '',
        'experienceLevel': '',
        'bodyMetrics': <String, dynamic>{'weightKg': null, 'heightCm': null},
        'preferences': <String, dynamic>{'tags': <String>[]},
        'profileCompleted': false,
        'profileCompletedAt': null,
        'onboardingVersion': 2,
      }, SetOptions(merge: false));

      return {
        'memberId': user.uid,
        'name': name,
        'gymId': resolvedGymId,
        'profileCompleted': false,
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
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    _googleInitialized = true;
  }

  static Future<Map<String, dynamic>?> _memberResultForUser(User? user) async {
    if (user == null) return null;
    final doc = await _db.collection('members').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    final profileCompleted = _isProfileCompleteData(data);
    return {
      'memberId': doc.id,
      'name': data['name'] as String? ?? user.displayName ?? 'Member',
      'gymId': data['gymId'] as String? ?? BasicGymConfig.gymId,
      'email': data['email'] as String? ?? user.email ?? '',
      'phone': data['phone'] as String? ?? '',
      'profileCompleted': profileCompleted,
    };
  }

  static bool _isProfileCompleteData(Map<String, dynamic> data) {
    final goal = (data['goal'] as String? ?? '').trim();
    final activityLevel = (data['activityLevel'] as String? ?? '').trim();
    if (goal.isEmpty || activityLevel.isEmpty) return false;
    return true;
  }

  static Future<bool> needsProfileCompletion(String memberId) async {
    final member = await getMember(memberId);
    if (member == null) return false;
    return !_isProfileCompleteData(member);
  }

  static Future<bool> completeProfile({
    required String memberId,
    required String goal,
    required String activityLevel,
    String? experienceLevel,
    double? weightKg,
    double? heightCm,
    List<String> preferences = const [],
  }) async {
    try {
      final safeWeightKg = _normalizeWeightKg(weightKg);
      final safeHeightCm = _normalizeHeightCm(heightCm);
      await _db.collection('members').doc(memberId).update({
        'goal': goal.trim(),
        'activityLevel': activityLevel.trim(),
        'experienceLevel': (experienceLevel ?? '').trim(),
        'bodyMetrics': <String, dynamic>{
          'weightKg': safeWeightKg,
          'heightCm': safeHeightCm,
        },
        'preferences': <String, dynamic>{'tags': preferences},
        'profileCompleted': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> mergeGuestSessionData({
    required String memberId,
    required int starterWorkoutsCompleted,
    required int meaningfulActionCount,
    required String lastAction,
  }) async {
    try {
      if (starterWorkoutsCompleted <= 0 &&
          meaningfulActionCount <= 0 &&
          lastAction.isEmpty) {
        return;
      }
      await _db.collection('members').doc(memberId).set({
        'guestSessionMerge': {
          'starterWorkoutsCompleted': starterWorkoutsCompleted,
          'meaningfulActionCount': meaningfulActionCount,
          'lastAction': lastAction,
          'mergedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<String> _resolveDefaultGymId() async {
    try {
      final defaultGym = await _db
          .collection('gyms')
          .doc(BasicGymConfig.gymId)
          .get();
      if (defaultGym.exists) return defaultGym.id;
      final anyGym = await _db.collection('gyms').limit(1).get();
      if (anyGym.docs.isNotEmpty) return anyGym.docs.first.id;
    } catch (_) {}
    return BasicGymConfig.gymId;
  }

  static Future<String> _resolveRegistrationGymId(String? selectedGymId) async {
    final candidate = selectedGymId?.trim() ?? '';
    if (candidate.isNotEmpty) {
      try {
        final doc = await _db.collection('gyms').doc(candidate).get();
        if (doc.exists) return doc.id;
      } catch (_) {}
    }
    return _resolveDefaultGymId();
  }

  static String _nameFromEmail(String email) {
    final handle = email.split('@').first.trim();
    if (handle.isEmpty) return 'Member';
    final clean = handle.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim();
    if (clean.isEmpty) return 'Member';
    return clean
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
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
    } catch (_) {
      return null;
    }
  }

  // ── Gym ──────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getGym(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, String>>> registrationGyms() async {
    try {
      final snap = await _db.collection('gyms').get();
      final gyms = <Map<String, String>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').trim();
        final code =
            (data['gymCodeNormalized'] as String? ??
                    data['gymCode'] as String? ??
                    '')
                .trim();
        gyms.add({
          'id': doc.id,
          'name': name.isEmpty ? doc.id : name,
          'code': code,
        });
      }
      gyms.sort(
        (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
      );
      return gyms;
    } catch (_) {
      return const [];
    }
  }

  static String normalizeGymCode(String code) {
    final normalized = code.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static Future<Map<String, dynamic>?> findGymByCode(String code) async {
    final normalized = normalizeGymCode(code);
    if (normalized.isEmpty) return null;

    try {
      final snap = await _db
          .collection('gyms')
          .where('gymCodeNormalized', isEqualTo: normalized)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        return {'id': doc.id, ...doc.data()};
      }

      final legacySnap = await _db
          .collection('gyms')
          .where('gymCode', isEqualTo: normalized)
          .limit(1)
          .get();
      if (legacySnap.docs.isNotEmpty) {
        final doc = legacySnap.docs.first;
        return {'id': doc.id, ...doc.data()};
      }

      if (normalized == normalizeGymCode(BasicGymConfig.gymCode)) {
        final doc = await _db
            .collection('gyms')
            .doc(BasicGymConfig.gymId)
            .get();
        if (doc.exists) return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateGymLocation(
    String gymId,
    double lat,
    double lng,
  ) async {
    try {
      await _db.collection('gyms').doc(gymId).update({
        'latitude': lat,
        'longitude': lng,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static DateTime _nowUtc() => DateTime.now().toUtc();

  static Future<QuerySnapshot<Map<String, dynamic>>> _openSessionQuery(
    String memberId,
  ) {
    return _db
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .where('checkedOut', isNull: true)
        .limit(1)
        .get();
  }

  static String _sessionStateFromCheckoutReason(String reason) {
    switch (reason) {
      case 'auto':
        return _sessionStateAutoClosed;
      case 'force':
        return _sessionStateForceCheckedOut;
      default:
        return _sessionStateCheckedOut;
    }
  }

  static Future<void> _logAttendanceAudit(
    String sessionId, {
    required String event,
    required String actor,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _db
          .collection('attendance')
          .doc(sessionId)
          .collection('auditLogs')
          .add({
            'event': event,
            'actor': actor,
            'payload': payload ?? const <String, dynamic>{},
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  static Future<String?> _createAttendanceSession({
    required String memberId,
    required String gymId,
    required DateTime checkedInUtc,
    required String source,
    required String checkInMethod,
    required String workoutType,
    required String notes,
    required String actor,
  }) async {
    final open = await _openSessionQuery(memberId);
    if (open.docs.isNotEmpty) return open.docs.first.id;

    final timezoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final ref = await _db.collection('attendance').add({
      'memberId': memberId,
      'gymId': gymId,
      'checkedIn': Timestamp.fromDate(checkedInUtc),
      'checkedInServerAt': FieldValue.serverTimestamp(),
      'checkedInTimezoneOffsetMinutes': timezoneOffsetMinutes,
      'checkedOut': null,
      'checkedOutServerAt': null,
      'sessionState': _sessionStateCheckedIn,
      'source': source,
      'checkInMethod': checkInMethod,
      'checkoutReason': '',
      'workoutType': workoutType,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logAttendanceAudit(
      ref.id,
      event: 'check_in',
      actor: actor,
      payload: {
        'source': source,
        'checkInMethod': checkInMethod,
        'checkedInUtc': checkedInUtc.toIso8601String(),
      },
    );
    return ref.id;
  }

  // ── Auto Attendance ───────────────────────────────────────────────────────────

  static Future<String?> checkIn(String memberId, String gymId) async {
    try {
      return _createAttendanceSession(
        memberId: memberId,
        gymId: gymId,
        checkedInUtc: _nowUtc(),
        source: 'auto',
        checkInMethod: 'geofence_auto',
        workoutType: '',
        notes: '',
        actor: 'member',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> quickManualCheckIn({
    required String memberId,
    required String gymId,
    String checkInMethod = 'manual_quick',
  }) async {
    try {
      final open = await _openSessionQuery(memberId);
      if (open.docs.isNotEmpty) return null;
      return _createAttendanceSession(
        memberId: memberId,
        gymId: gymId,
        checkedInUtc: _nowUtc(),
        source: 'manual',
        checkInMethod: checkInMethod,
        workoutType: 'General',
        notes: '',
        actor: 'member',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> checkOut(
    String sessionId, {
    String reason = 'member',
  }) async {
    try {
      final docRef = _db.collection('attendance').doc(sessionId);
      final doc = await docRef.get();
      if (!doc.exists) return;
      final data = doc.data() ?? const <String, dynamic>{};
      if (data['checkedOut'] != null) return;

      final checkedOutUtc = _nowUtc();
      await docRef.update({
        'checkedOut': Timestamp.fromDate(checkedOutUtc),
        'checkedOutServerAt': FieldValue.serverTimestamp(),
        'checkoutReason': reason,
        'sessionState': _sessionStateFromCheckoutReason(reason),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _logAttendanceAudit(
        sessionId,
        event: 'check_out',
        actor: reason == 'force' ? 'admin' : 'member',
        payload: {
          'reason': reason,
          'checkedOutUtc': checkedOutUtc.toIso8601String(),
        },
      );
    } catch (_) {}
  }

  // ── Manual Attendance Form ────────────────────────────────────────────────────

  static Future<String?> manualCheckIn({
    required String memberId,
    required String gymId,
    required String workoutType,
    required String notes,
    required DateTime checkedIn,
    String source = 'manual',
    String checkInMethod = 'manual_form',
  }) async {
    try {
      final open = await _openSessionQuery(memberId);
      if (open.docs.isNotEmpty) return null;
      return _createAttendanceSession(
        memberId: memberId,
        gymId: gymId,
        checkedInUtc: checkedIn.toUtc(),
        source: source,
        checkInMethod: checkInMethod,
        workoutType: workoutType,
        notes: notes,
        actor: 'member',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> checkInWithGymCode({
    required String memberId,
    required String gymCode,
  }) async {
    final gym = await findGymByCode(gymCode);
    if (gym == null) {
      return {'ok': false, 'error': 'Invalid gym code.'};
    }

    final gymId = gym['id'] as String;
    final sessionId = await manualCheckIn(
      memberId: memberId,
      gymId: gymId,
      workoutType: 'General',
      notes: '',
      checkedIn: DateTime.now(),
      source: 'qr',
      checkInMethod: 'qr_code',
    );
    if (sessionId == null) {
      return {
        'ok': false,
        'error': 'You already have an active session. Please check out first.',
      };
    }

    return {'ok': true, 'sessionId': sessionId, 'gymId': gymId};
  }

  static Future<bool> updateAttendanceForm({
    required String sessionId,
    required String workoutType,
    required String notes,
    DateTime? checkedOut,
    String editedBy = 'member',
    String? correctionNote,
  }) async {
    try {
      final update = <String, dynamic>{
        'workoutType': workoutType,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (checkedOut != null) {
        update['checkedOut'] = Timestamp.fromDate(checkedOut.toUtc());
        update['checkedOutServerAt'] = FieldValue.serverTimestamp();
        update['checkoutReason'] = 'manual_edit';
        update['sessionState'] = _sessionStateCheckedOut;
      }

      await _db.collection('attendance').doc(sessionId).update(update);
      await _logAttendanceAudit(
        sessionId,
        event: 'attendance_correction',
        actor: editedBy,
        payload: {
          'workoutType': workoutType,
          'hasCheckedOut': checkedOut != null,
          'correctionNote': correctionNote ?? '',
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAttendance(
    String sessionId, {
    String deletedBy = 'member',
    String reason = 'user_deleted',
  }) async {
    try {
      final ref = _db.collection('attendance').doc(sessionId);
      final doc = await ref.get();
      final snapshot = doc.data();
      if (snapshot != null) {
        await _db.collection('attendance_deletions').add({
          'sessionId': sessionId,
          'deletedBy': deletedBy,
          'reason': reason,
          'snapshot': snapshot,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────────

  static Future<void> notifyExit(String memberId) async {
    try {
      await _db.collection('exit_requests').add({
        'memberId': memberId,
        'requestedAt': FieldValue.serverTimestamp(),
        'handled': false,
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
        'memberId': memberId,
        'gymId': gymId,
        'message': message,
        'category': category,
        'resolved': false,
        'adminNote': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateProfile({
    required String memberId,
    required String name,
    required String emergencyContact,
    required String membershipType,
    String? goal,
    String? activityLevel,
    String? experienceLevel,
    double? weightKg,
    double? heightCm,
    List<String>? preferences,
    bool overwriteBodyMetrics = false,
    bool overwritePreferences = false,
  }) async {
    try {
      final safeWeightKg = _normalizeWeightKg(weightKg);
      final safeHeightCm = _normalizeHeightCm(heightCm);
      final update = <String, dynamic>{
        'name': name,
        'emergencyContact': emergencyContact,
        'membershipType': membershipType,
      };

      if (goal != null) update['goal'] = goal.trim();
      if (activityLevel != null) update['activityLevel'] = activityLevel.trim();
      if (experienceLevel != null) {
        update['experienceLevel'] = experienceLevel.trim();
      }
      if (overwriteBodyMetrics) {
        update['bodyMetrics'] = <String, dynamic>{
          'weightKg': safeWeightKg,
          'heightCm': safeHeightCm,
        };
      }
      if (overwritePreferences) {
        update['preferences'] = <String, dynamic>{
          'tags': (preferences ?? const <String>[])
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
        };
      }
      if (goal != null || activityLevel != null) {
        final goalValue = (goal ?? '').trim();
        final activityValue = (activityLevel ?? '').trim();
        final profileCompleted =
            goalValue.isNotEmpty && activityValue.isNotEmpty;
        update['profileCompleted'] = profileCompleted;
        if (profileCompleted) {
          update['profileCompletedAt'] = FieldValue.serverTimestamp();
        }
      }

      await _db.collection('members').doc(memberId).update(update);
      return true;
    } catch (_) {
      return false;
    }
  }

  static double? _normalizeWeightKg(double? rawWeight) {
    if (rawWeight == null || rawWeight <= 0) return null;
    return double.parse(rawWeight.toStringAsFixed(1));
  }

  static double? _normalizeHeightCm(double? rawHeight) {
    if (rawHeight == null || rawHeight <= 0) return null;

    double valueCm;
    if (rawHeight >= 0.8 && rawHeight <= 2.8) {
      // Input in meters (e.g. 1.72)
      valueCm = rawHeight * 100;
    } else if (rawHeight >= 3 && rawHeight <= 8.5) {
      // Input in feet (e.g. 5.8)
      valueCm = rawHeight * 30.48;
    } else {
      // Assume centimeters (e.g. 172)
      valueCm = rawHeight;
    }

    if (valueCm < 80 || valueCm > 260) return null;
    return double.parse(valueCm.toStringAsFixed(1));
  }

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

  // ── Stats ─────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats(String memberId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);
      final last30Start = now.subtract(const Duration(days: 30));
      final lookbackStart = today.subtract(const Duration(days: 60));

      final snap = await _db
          .collection('attendance')
          .where('memberId', isEqualTo: memberId)
          .where(
            'checkedIn',
            isGreaterThanOrEqualTo: Timestamp.fromDate(lookbackStart),
          )
          .orderBy('checkedIn', descending: false)
          .get();

      final records = snap.docs.map((d) {
        final data = d.data();
        final checkedIn = _toDateTime(data['checkedIn'], fallback: now);
        return AttendanceRecord(
          id: d.id,
          checkedIn: checkedIn,
          checkedOut: data['checkedOut'] == null
              ? null
              : _toDateTime(data['checkedOut'], fallback: checkedIn),
          source: data['source'] ?? 'auto',
          workoutType: data['workoutType'] ?? '',
          notes: data['notes'] ?? '',
        );
      }).toList();

      final monthRecords = records
          .where((r) => !r.checkedIn.isBefore(monthStart))
          .toList();
      final weekRecords = records
          .where((r) => !r.checkedIn.isBefore(weekStart))
          .toList();
      final last30Records = records
          .where((r) => !r.checkedIn.isBefore(last30Start))
          .toList();
      final closedAll = monthRecords.where((r) => !r.isOpen).toList();
      final closedWeek = weekRecords.where((r) => !r.isOpen).toList();
      final openSessions = monthRecords.where((r) => r.isOpen).length;

      final totalMinutes = closedAll.fold<int>(
        0,
        (s, r) => s + _safeDurationMinutes(r.checkedIn, r.checkedOut!),
      );
      final weekMinutes = closedWeek.fold<int>(
        0,
        (s, r) => s + _safeDurationMinutes(r.checkedIn, r.checkedOut!),
      );
      final missedCheckoutRate = monthRecords.isEmpty
          ? 0.0
          : openSessions / monthRecords.length;

      final typeCount = <String, int>{};
      for (final r in closedAll) {
        if (r.workoutType != null && r.workoutType!.isNotEmpty) {
          typeCount[r.workoutType!] = (typeCount[r.workoutType!] ?? 0) + 1;
        }
      }
      final topType = typeCount.isEmpty
          ? '-'
          : typeCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      final dailyVisits = List<int>.filled(7, 0);
      for (final r in weekRecords) {
        final day = DateTime(
          r.checkedIn.year,
          r.checkedIn.month,
          r.checkedIn.day,
        );
        final daysAgo = today.difference(day).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          dailyVisits[6 - daysAgo]++;
        }
      }

      int streak = 0;
      for (int i = 0; i <= 60; i++) {
        final day = today.subtract(Duration(days: i));
        final hasVisit = records.any((r) {
          final d = r.checkedIn;
          return d.year == day.year && d.month == day.month && d.day == day.day;
        });
        if (hasVisit) {
          streak++;
        } else {
          break;
        }
      }

      final hourCounts = List<int>.filled(24, 0);
      for (final r in monthRecords) {
        hourCounts[r.checkedIn.hour]++;
      }
      final maxHour = hourCounts.reduce((a, b) => a > b ? a : b);
      final peakHour = maxHour == 0 ? -1 : hourCounts.indexOf(maxHour);

      return {
        'monthVisits': monthRecords.length,
        'weekVisits': weekRecords.length,
        'visitsLast7': weekRecords.length,
        'visitsLast30': last30Records.length,
        'totalMinutes': totalMinutes,
        'weekMinutes': weekMinutes,
        'avgMinutes': closedAll.isEmpty ? 0 : totalMinutes ~/ closedAll.length,
        'openSessions': openSessions,
        'missedCheckoutRate': missedCheckoutRate,
        'peakHour': peakHour,
        'streak': streak,
        'topWorkout': topType,
        'dailyVisits': dailyVisits,
        'typeCount': typeCount,
      };
    } catch (_) {
      return {
        'monthVisits': 0,
        'weekVisits': 0,
        'visitsLast7': 0,
        'visitsLast30': 0,
        'totalMinutes': 0,
        'weekMinutes': 0,
        'avgMinutes': 0,
        'openSessions': 0,
        'missedCheckoutRate': 0.0,
        'peakHour': -1,
        'streak': 0,
        'topWorkout': '-',
        'dailyVisits': List<int>.filled(7, 0),
        'typeCount': <String, int>{},
      };
    }
  }

  static Stream<List<AttendanceRecord>> historyStream(String memberId) {
    return _db
        .collection('attendance')
        .where('memberId', isEqualTo: memberId)
        .orderBy('checkedIn', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            final checkedIn = _toDateTime(
              data['checkedIn'],
              fallback: DateTime.now(),
            );
            return AttendanceRecord(
              id: d.id,
              checkedIn: checkedIn,
              checkedOut: data['checkedOut'] == null
                  ? null
                  : _toDateTime(data['checkedOut'], fallback: checkedIn),
              source: data['source'] ?? 'auto',
              workoutType: data['workoutType'] ?? '',
              notes: data['notes'] ?? '',
            );
          }).toList(),
        );
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
          final d = snap.docs.first;
          final data = d.data();
          final checkedIn = _toDateTime(
            data['checkedIn'],
            fallback: DateTime.now(),
          );
          return AttendanceRecord(
            id: d.id,
            checkedIn: checkedIn,
            checkedOut: null,
            source: data['source'] ?? 'auto',
            workoutType: data['workoutType'] ?? '',
            notes: data['notes'] ?? '',
          );
        });
  }
}
