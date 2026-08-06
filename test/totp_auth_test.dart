import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/models/user_account.dart';
import 'package:attendance_app/services/totp_service.dart';
import 'package:attendance_app/services/jwt_session_service.dart';

void main() {
  group('TOTP Authentication Tests', () {
    test('Verify 4 authorized user accounts exist', () {
      final users = UserAccount.defaultUsers;
      expect(users.length, equals(4));
      expect(users.map((u) => u.username), containsAll(['Allen Admin', 'user1', 'user2', 'user3']));
    });

    test('Generate and verify valid TOTP code', () {
      final user = UserAccount.defaultUsers.first; // Allen
      final code = TotpService.generateTotp(user.totpSecret);
      
      expect(code.length, equals(6));
      expect(int.tryParse(code), isNotNull);

      final isValid = TotpService.verifyTotp(user.totpSecret, code);
      expect(isValid, isTrue);
    });

    test('Reject invalid TOTP code', () {
      final user = UserAccount.defaultUsers.first;
      final isValid = TotpService.verifyTotp(user.totpSecret, '000000');
      // Unless 000000 happens to be current code (extremely unlikely), should be false or verified
      final currentCode = TotpService.generateTotp(user.totpSecret);
      if (currentCode != '000000') {
        expect(isValid, isFalse);
      }
    });

    test('Generate valid Google Authenticator otpauth URI', () {
      final uri = TotpService.generateKeyUri(username: 'Allen', secret: 'JBSWY3DPEHPK3PXP');
      expect(uri, contains('otpauth://totp/FestAttendance:Allen'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
    });

    test('Create and verify 2-hour JWT session', () {
      final session = JwtSessionService.createSession(
        username: 'Allen',
        displayName: 'Allen (Admin)',
        sessionDuration: const Duration(hours: 2),
      );

      expect(session.username, equals('Allen'));
      expect(session.isValid, isTrue);
      expect(session.remainingDuration.inMinutes, greaterThan(118));

      final parsedSession = JwtSessionService.verifyToken(session.token);
      expect(parsedSession, isNotNull);
      expect(parsedSession!.username, equals('Allen'));
      expect(parsedSession.isValid, isTrue);
    });

    test('Reject expired JWT session', () {
      final session = JwtSessionService.createSession(
        username: 'Allen',
        displayName: 'Allen (Admin)',
        sessionDuration: const Duration(seconds: -10), // Expired 10s ago
      );

      expect(session.isValid, isFalse);
      final parsedSession = JwtSessionService.verifyToken(session.token);
      expect(parsedSession, isNull);
    });
  });
}
