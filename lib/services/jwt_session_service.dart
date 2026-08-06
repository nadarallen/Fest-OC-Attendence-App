import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_session.dart';

class JwtSessionService {
  // Secret key used for signing JWT tokens in this session service
  static const String _secretKey = 'fest_oc_attendance_secure_jwt_secret_key_2026';

  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _base64UrlDecode(String input) {
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }
    return utf8.decode(base64.decode(normalized));
  }

  /// Creates a signed JWT session token valid for 2 hours.
  static UserSession createSession({
    required String username,
    required String displayName,
    Duration sessionDuration = const Duration(hours: 2),
  }) {
    final now = DateTime.now();
    final expiresAt = now.add(sessionDuration);

    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final payload = {
      'sub': username,
      'displayName': displayName,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'jti': '${username}_${now.millisecondsSinceEpoch}',
    };

    final headerString = _base64UrlEncode(utf8.encode(jsonEncode(header)));
    final payloadString = _base64UrlEncode(utf8.encode(jsonEncode(payload)));
    final signingInput = '$headerString.$payloadString';

    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final signature = _base64UrlEncode(hmac.convert(utf8.encode(signingInput)).bytes);

    final token = '$signingInput.$signature';

    return UserSession(
      token: token,
      username: username,
      displayName: displayName,
      issuedAt: now,
      expiresAt: expiresAt,
    );
  }

  /// Verifies a JWT token signature and expiration.
  static UserSession? verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final headerString = parts[0];
      final payloadString = parts[1];
      final signature = parts[2];

      final signingInput = '$headerString.$payloadString';
      final hmac = Hmac(sha256, utf8.encode(_secretKey));
      final expectedSignature = _base64UrlEncode(hmac.convert(utf8.encode(signingInput)).bytes);

      if (signature != expectedSignature) {
        // Invalid signature
        return null;
      }

      final payloadJson = jsonDecode(_base64UrlDecode(payloadString)) as Map<String, dynamic>;
      final username = payloadJson['sub'] as String;
      final displayName = payloadJson['displayName'] as String? ?? username;
      final iatSeconds = payloadJson['iat'] as int;
      final expSeconds = payloadJson['exp'] as int;

      final issuedAt = DateTime.fromMillisecondsSinceEpoch(iatSeconds * 1000);
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);

      final session = UserSession(
        token: token,
        username: username,
        displayName: displayName,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );

      if (!session.isValid) {
        // Expired token
        return null;
      }

      return session;
    } catch (e) {
      return null;
    }
  }
}
