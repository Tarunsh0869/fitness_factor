class AttendanceRecord {
  final String id;
  final DateTime checkedIn;
  final DateTime? checkedOut;
  final String source;
  final String? notes;
  final String? workoutType;
  final String? memberName;

  AttendanceRecord({
    required this.id,
    required this.checkedIn,
    this.checkedOut,
    required this.source,
    this.notes,
    this.workoutType,
    this.memberName,
  });

  Duration? get duration => checkedOut?.difference(checkedIn);
  bool get isOpen => checkedOut == null;
}
