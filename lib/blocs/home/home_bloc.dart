import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/attendance_record.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_prefs.dart';
import '../../services/firebase_service.dart';
import '../../services/geo_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class HomeEvent {}

class HomeInit extends HomeEvent {}

class HomeRefresh extends HomeEvent {}

class HomeSyncArrivalByLocation extends HomeEvent {
  final bool showFeedback;
  HomeSyncArrivalByLocation({this.showFeedback = true});
}

class HomeGeofenceChanged extends HomeEvent {
  final bool isInside;
  HomeGeofenceChanged(this.isInside);
}

class HomeCheckOutNow extends HomeEvent {}

class HomeQuickManualCheckIn extends HomeEvent {}

class HomeCheckInWithGymCode extends HomeEvent {
  final String code;
  HomeCheckInWithGymCode(this.code);
}

class HomeLogout extends HomeEvent {}

class HomeTabChanged extends HomeEvent {
  final int index;
  HomeTabChanged(this.index);
}

class _HomeSessionUpdated extends HomeEvent {
  final AttendanceRecord? session;
  _HomeSessionUpdated(this.session);
}

class _HomeHistoryUpdated extends HomeEvent {
  final List<AttendanceRecord> history;
  _HomeHistoryUpdated(this.history);
}

class _HomeStatsUpdated extends HomeEvent {
  final int weekVisits;
  _HomeStatsUpdated(this.weekVisits);
}

class _HomeTimerTick extends HomeEvent {}

class _HomeFcmExit extends HomeEvent {}

// ── State ─────────────────────────────────────────────────────────────────────
class HomeState {
  final bool isInsideGym;
  final bool geoReady;
  final bool checkingArrival;
  final bool manualCheckInLoading;
  final List<AttendanceRecord> history;
  final AttendanceRecord? openSession;
  final Duration elapsed;
  final String memberPhone;
  final String gymName;
  final int weekVisits;
  final int selectedTab;

  // one-shot feedback — consumed by BlocListener
  final String? snackMessage;
  final bool snackIsError;
  final bool showExitSheet;
  final bool navigateToLogout;
  final String? checkInError; // for QR/manual failures

  const HomeState({
    this.isInsideGym = false,
    this.geoReady = false,
    this.checkingArrival = false,
    this.manualCheckInLoading = false,
    this.history = const [],
    this.openSession,
    this.elapsed = Duration.zero,
    this.memberPhone = '',
    this.gymName = '',
    this.weekVisits = 0,
    this.selectedTab = 0,
    this.snackMessage,
    this.snackIsError = false,
    this.showExitSheet = false,
    this.navigateToLogout = false,
    this.checkInError,
  });

  HomeState copyWith({
    bool? isInsideGym,
    bool? geoReady,
    bool? checkingArrival,
    bool? manualCheckInLoading,
    List<AttendanceRecord>? history,
    AttendanceRecord? openSession,
    bool clearSession = false,
    Duration? elapsed,
    String? memberPhone,
    String? gymName,
    int? weekVisits,
    int? selectedTab,
    String? snackMessage,
    bool? snackIsError,
    bool? showExitSheet,
    bool? navigateToLogout,
    String? checkInError,
    bool clearOneShots = false,
  }) => HomeState(
    isInsideGym: isInsideGym ?? this.isInsideGym,
    geoReady: geoReady ?? this.geoReady,
    checkingArrival: checkingArrival ?? this.checkingArrival,
    manualCheckInLoading: manualCheckInLoading ?? this.manualCheckInLoading,
    history: history ?? this.history,
    openSession: clearSession ? null : (openSession ?? this.openSession),
    elapsed: elapsed ?? this.elapsed,
    memberPhone: memberPhone ?? this.memberPhone,
    gymName: gymName ?? this.gymName,
    weekVisits: weekVisits ?? this.weekVisits,
    selectedTab: selectedTab ?? this.selectedTab,
    snackMessage: clearOneShots ? null : (snackMessage ?? this.snackMessage),
    snackIsError: snackIsError ?? this.snackIsError,
    showExitSheet: clearOneShots ? false : (showExitSheet ?? this.showExitSheet),
    navigateToLogout:
        clearOneShots ? false : (navigateToLogout ?? this.navigateToLogout),
    checkInError: clearOneShots ? null : (checkInError ?? this.checkInError),
  );
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

/// Manages all state for HomeScreen: geo, check-in/out, history, timer, stats.
///
/// One-shot side-effects (snackbar, logout nav, exit sheet) are set on state
/// and cleared by the screen via [HomeState.clearOneShots].
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final String memberId;
  final String gymId;

  StreamSubscription? _sessionSub;
  StreamSubscription? _historySub;
  StreamSubscription? _statsSub;
  StreamSubscription? _geoSub;
  StreamSubscription? _fcmSub;
  Timer? _sessionTimer;
  Timer? _autoCheckoutTimer;
  bool _geofenceStarted = false;

  HomeBloc({required this.memberId, required this.gymId})
    : super(const HomeState()) {
    on<HomeInit>(_onInit);
    on<HomeRefresh>(_onRefresh);
    on<HomeSyncArrivalByLocation>(_onSyncArrival);
    on<HomeGeofenceChanged>(_onGeofenceChanged);
    on<HomeCheckOutNow>(_onCheckOut);
    on<HomeQuickManualCheckIn>(_onQuickManualCheckIn);
    on<HomeCheckInWithGymCode>(_onCheckInWithGymCode);
    on<HomeLogout>(_onLogout);
    on<HomeTabChanged>((e, emit) => emit(state.copyWith(selectedTab: e.index)));
    on<_HomeSessionUpdated>(_onSessionUpdated);
    on<_HomeHistoryUpdated>(
      (e, emit) => emit(state.copyWith(history: e.history)),
    );
    on<_HomeStatsUpdated>(
      (e, emit) => emit(state.copyWith(weekVisits: e.weekVisits)),
    );
    on<_HomeTimerTick>(
      (e, emit) => emit(
        state.copyWith(
          elapsed: state.openSession != null
              ? DateTime.now().difference(state.openSession!.checkedIn)
              : Duration.zero,
        ),
      ),
    );
    on<_HomeFcmExit>(
      (e, emit) => emit(state.copyWith(showExitSheet: true)),
    );
  }

  Future<void> _onInit(HomeInit e, Emitter<HomeState> emit) async {
    _sessionSub = AttendanceService.openSessionStream(memberId).listen((s) {
      add(_HomeSessionUpdated(s));
    });
    _historySub = AttendanceService.historyStream(memberId).listen((h) {
      add(_HomeHistoryUpdated(h));
    });
    _statsSub = AttendanceService.statsStream(memberId).listen((s) {
      add(_HomeStatsUpdated(s['weekVisits'] as int));
    });
    await _loadMeta(emit);
    _fcmSub = FirebaseService.exitConfirmationStream().listen((_) {
      if (state.openSession != null) add(_HomeFcmExit());
    });
  }

  Future<void> _onRefresh(HomeRefresh e, Emitter<HomeState> emit) =>
      _loadMeta(emit);

  Future<void> _loadMeta(Emitter<HomeState> emit) async {
    final results = await Future.wait([
      AttendanceService.getMember(memberId),
      AttendanceService.getGym(gymId),
    ]);
    final member = results[0] as Map<String, dynamic>?;
    final gym = results[1] as Map<String, dynamic>?;
    final gymName = (gym?['name'] as String? ?? '').trim();
    emit(state.copyWith(
      memberPhone: member?['phone'] as String? ?? '',
      gymName: gymName.isEmpty ? gymId : gymName,
    ));
  }

  void _onSessionUpdated(_HomeSessionUpdated e, Emitter<HomeState> emit) {
    final session = e.session;
    if (session != null) {
      emit(state.copyWith(
        openSession: session,
        isInsideGym: true,
        elapsed: DateTime.now().difference(session.checkedIn),
      ));
      _startSessionTimer();
    } else {
      _sessionTimer?.cancel();
      emit(state.copyWith(clearSession: true, elapsed: Duration.zero));
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_HomeTimerTick());
    });
  }

  void _startAutoCheckoutTimer() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = Timer(const Duration(minutes: 5), () {
      add(HomeCheckOutNow());
    });
  }

  Future<void> _ensureGeofenceStarted(Emitter<HomeState> emit) async {
    if (_geofenceStarted) return;
    final granted = await GeoService.requestPermission();
    if (!granted) return;
    final gym = await AttendanceService.getGym(gymId);
    if (gym == null) return;
    _geofenceStarted = true;
    emit(state.copyWith(geoReady: true));
    _geoSub = GeoService.watchGeofence(
      gymLat: (gym['latitude'] as num).toDouble(),
      gymLng: (gym['longitude'] as num).toDouble(),
      radiusMeters: (gym['radiusMeters'] as num).toDouble(),
    ).listen((inside) => add(HomeGeofenceChanged(inside)));
  }

  Future<void> _onGeofenceChanged(
    HomeGeofenceChanged e,
    Emitter<HomeState> emit,
  ) async {
    await _applyLocationAttendance(e.isInside, emit, showFeedback: false);
  }

  Future<void> _onSyncArrival(
    HomeSyncArrivalByLocation e,
    Emitter<HomeState> emit,
  ) async {
    if (state.checkingArrival) return;
    emit(state.copyWith(checkingArrival: true, clearOneShots: true));
    try {
      await _ensureGeofenceStarted(emit);
      final gym = await AttendanceService.getGym(gymId);
      final lat = gym?['latitude'];
      final lng = gym?['longitude'];
      final radius = gym?['radiusMeters'];
      if (lat is! num || lng is! num) {
        if (e.showFeedback) {
          emit(state.copyWith(
            snackMessage: 'Gym location is not configured.',
            snackIsError: true,
          ));
        }
        return;
      }
      final isInside = await GeoService.isInsideGeofence(
        gymLat: lat.toDouble(),
        gymLng: lng.toDouble(),
        radiusMeters: radius is num ? radius.toDouble() : 50,
      );
      if (isInside == null) {
        if (e.showFeedback) {
          emit(state.copyWith(
            snackMessage: 'Could not read your current location.',
            snackIsError: true,
          ));
        }
        return;
      }
      await _applyLocationAttendance(isInside, emit, showFeedback: e.showFeedback);
    } finally {
      emit(state.copyWith(checkingArrival: false));
    }
  }

  Future<void> _applyLocationAttendance(
    bool isInside,
    Emitter<HomeState> emit, {
    required bool showFeedback,
  }) async {
    emit(state.copyWith(isInsideGym: isInside));
    if (isInside) {
      _autoCheckoutTimer?.cancel();
      if (state.openSession != null) {
        if (showFeedback) {
          emit(state.copyWith(
            snackMessage: 'You are already checked in.',
            snackIsError: false,
          ));
        }
        return;
      }
      final id = await AttendanceService.checkIn(memberId, gymId);
      if (showFeedback) {
        emit(id == null
            ? state.copyWith(
                snackMessage: 'Arrival found, but check-in failed.',
                snackIsError: true,
              )
            : state.copyWith(
                snackMessage: 'Arrival confirmed. Check-in started.',
                snackIsError: false,
              ));
      }
    } else {
      if (state.openSession != null) {
        await AttendanceService.notifyExit(memberId);
        _startAutoCheckoutTimer();
        if (showFeedback) {
          emit(state.copyWith(
            snackMessage: 'You are outside the gym. Exit confirmation sent.',
            snackIsError: false,
          ));
        }
      } else {
        if (showFeedback) {
          emit(state.copyWith(
            snackMessage: 'You are outside the gym range.',
            snackIsError: true,
          ));
        }
      }
    }
  }

  Future<void> _onCheckOut(HomeCheckOutNow e, Emitter<HomeState> emit) async {
    final session = state.openSession;
    if (session == null) return;
    _autoCheckoutTimer?.cancel();
    await AttendanceService.checkOut(session.id);
    emit(state.copyWith(snackMessage: 'Session checked out.', snackIsError: false));
  }

  Future<void> _onQuickManualCheckIn(
    HomeQuickManualCheckIn e,
    Emitter<HomeState> emit,
  ) async {
    if (state.manualCheckInLoading || state.openSession != null) return;
    emit(state.copyWith(manualCheckInLoading: true, clearOneShots: true));
    final sessionId = await AttendanceService.quickManualCheckIn(
      memberId: memberId,
      gymId: gymId,
    );
    emit(state.copyWith(
      manualCheckInLoading: false,
      snackMessage: sessionId == null
          ? 'Could not check in. You may already have an open session.'
          : 'Manual check-in successful.',
      snackIsError: sessionId == null,
    ));
  }

  Future<void> _onCheckInWithGymCode(
    HomeCheckInWithGymCode e,
    Emitter<HomeState> emit,
  ) async {
    final result = await AttendanceService.checkInWithGymCode(
      memberId: memberId,
      gymCode: e.code,
    );
    if (result['ok'] == true) {
      emit(state.copyWith(snackMessage: 'QR check-in successful.', snackIsError: false));
    } else {
      emit(state.copyWith(
        snackMessage: result['error'] as String? ?? 'QR check-in failed.',
        snackIsError: true,
      ));
    }
  }

  Future<void> _onLogout(HomeLogout e, Emitter<HomeState> emit) async {
    await AttendanceService.logout();
    await AuthPrefs.clear();
    emit(state.copyWith(navigateToLogout: true));
  }

  @override
  Future<void> close() {
    _sessionSub?.cancel();
    _historySub?.cancel();
    _statsSub?.cancel();
    _geoSub?.cancel();
    _fcmSub?.cancel();
    _sessionTimer?.cancel();
    _autoCheckoutTimer?.cancel();
    return super.close();
  }
}


