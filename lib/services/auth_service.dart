import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';
import '../models/user_session.dart';
import 'totp_service.dart';
import 'jwt_session_service.dart';

class AuthService {
  static const String _prefSessionTokenKey = 'auth_session_jwt_token';
  static const String _displayNamePrefix = 'user_display_name_';

  /// Returns the 4 authorized user accounts
  List<UserAccount> getAuthorizedUsers() {
    return UserAccount.defaultUsers;
  }

  /// Async fetch authorized users with any custom display names stored in SharedPreferences
  Future<List<UserAccount>> getAuthorizedUsersAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return UserAccount.defaultUsers.map((user) {
      final customName = prefs.getString('$_displayNamePrefix${user.username}');
      if (customName != null && customName.trim().isNotEmpty) {
        return user.copyWith(displayName: customName.trim());
      }
      return user;
    }).toList();
  }

  /// Updates the display name for a given user account
  Future<void> updateDisplayName(String username, String newDisplayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_displayNamePrefix$username', newDisplayName.trim());
  }

  /// Finds an authorized user account by username or display name (case-insensitive)
  Future<UserAccount?> findUserAsync(String inputName) async {
    final users = await getAuthorizedUsersAsync();
    final cleanInput = inputName.trim().toLowerCase();
    for (var user in users) {
      if (user.username.toLowerCase() == cleanInput ||
          user.displayName.toLowerCase() == cleanInput) {
        return user;
      }
    }
    return null;
  }

  /// Authenticates a user with username/display name and 6-digit TOTP code
  Future<UserSession> login({
    required String username,
    required String totpCode,
  }) async {
    final user = await findUserAsync(username);
    if (user == null) {
      throw Exception('Invalid user account. User is not authorized.');
    }

    final isValidTotp = TotpService.verifyTotp(user.totpSecret, totpCode);
    if (!isValidTotp) {
      throw Exception('Invalid Google Authenticator code. Please enter the current 6-digit code.');
    }

    // Create 2-hour JWT session
    final session = JwtSessionService.createSession(
      username: user.username,
      displayName: user.displayName,
      sessionDuration: const Duration(hours: 2),
    );

    // Save session token locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSessionTokenKey, session.token);

    return session;
  }

  /// Loads and verifies any stored session
  Future<UserSession?> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefSessionTokenKey);

      if (token == null || token.isEmpty) {
        return null;
      }

      final session = JwtSessionService.verifyToken(token);
      if (session == null || !session.isValid) {
        // Session expired or invalid, clean up
        await logout();
        return null;
      }

      return session;
    } catch (e) {
      return null;
    }
  }

  /// Logs out the user and clears stored session data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefSessionTokenKey);
  }
}
