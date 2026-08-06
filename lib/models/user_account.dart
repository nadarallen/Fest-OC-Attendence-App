class UserAccount {
  final String username;
  final String displayName;
  final String totpSecret;
  final bool isSetupCompleted;

  const UserAccount({
    required this.username,
    required this.displayName,
    required this.totpSecret,
    this.isSetupCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'totpSecret': totpSecret,
      'isSetupCompleted': isSetupCompleted ? 1 : 0,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      username: map['username'] as String,
      displayName: map['displayName'] as String? ?? map['username'] as String,
      totpSecret: map['totpSecret'] as String,
      isSetupCompleted: (map['isSetupCompleted'] is int)
          ? (map['isSetupCompleted'] as int) == 1
          : (map['isSetupCompleted'] as bool? ?? false),
    );
  }

  UserAccount copyWith({
    String? username,
    String? displayName,
    String? totpSecret,
    bool? isSetupCompleted,
  }) {
    return UserAccount(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      totpSecret: totpSecret ?? this.totpSecret,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
    );
  }

  /// Exact 4 authorized users for the application
  static List<UserAccount> get defaultUsers => const [
        UserAccount(
          username: 'Allen Admin',
          displayName: 'Allen Admin',
          totpSecret: 'JBSWY3DPEHPK3PXP',
        ),
        UserAccount(
          username: 'user1',
          displayName: 'user1',
          totpSecret: 'KVKFKRCPNZQUYMLS',
        ),
        UserAccount(
          username: 'user2',
          displayName: 'user2',
          totpSecret: 'MZXW6YTBOIJW4ZZP',
        ),
        UserAccount(
          username: 'user3',
          displayName: 'user3',
          totpSecret: 'NXW2CZLSMFUG64TW',
        ),
      ];
}
