class UserSession {
  final String token;
  final String username;
  final String displayName;
  final DateTime issuedAt;
  final DateTime expiresAt;

  UserSession({
    required this.token,
    required this.username,
    required this.displayName,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get formattedRemainingTime {
    final rem = remainingDuration;
    if (rem.inSeconds <= 0) return "00:00:00";
    final hours = rem.inHours.toString().padLeft(2, '0');
    final minutes = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'username': username,
      'displayName': displayName,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      token: map['token'] as String,
      username: map['username'] as String,
      displayName: map['displayName'] as String? ?? map['username'] as String,
      issuedAt: DateTime.parse(map['issuedAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }
}
