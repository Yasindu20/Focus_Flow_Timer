class UserGoals {
  final String userId;
  final int dailySessions;
  final int weeklyHours;

  UserGoals({
    required this.userId,
    required this.dailySessions,
    required this.weeklyHours,
  });

  factory UserGoals.fromFirestore(Map<String, dynamic> data) {
    return UserGoals(
      userId: data['userId'] ?? '',
      dailySessions: data['dailySessions'] ?? 4,
      weeklyHours: data['weeklyHours'] ?? 20,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'dailySessions': dailySessions,
      'weeklyHours': weeklyHours,
    };
  }

  UserGoals copyWith({
    String? userId,
    int? dailySessions,
    int? weeklyHours,
  }) {
    return UserGoals(
      userId: userId ?? this.userId,
      dailySessions: dailySessions ?? this.dailySessions,
      weeklyHours: weeklyHours ?? this.weeklyHours,
    );
  }
}