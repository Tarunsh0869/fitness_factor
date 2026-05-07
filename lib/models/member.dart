class Member {
  final String id;
  final String name;
  final String phone;
  final String emergencyContact;
  final String membershipType;
  final String gender;
  final DateTime? dateOfBirth;
  final String gymId;
  final String fcmToken;
  final DateTime createdAt;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.emergencyContact,
    required this.membershipType,
    required this.gender,
    this.dateOfBirth,
    required this.gymId,
    this.fcmToken = '',
    required this.createdAt,
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}
