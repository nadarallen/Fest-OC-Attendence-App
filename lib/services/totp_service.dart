import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class TotpService {
  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Decodes a Base32 encoded string into raw bytes.
  static List<int> _decodeBase32(String input) {
    final cleanInput = input
        .replaceAll('=', '')
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z2-7]'), '');

    List<int> bytes = [];
    int buffer = 0;
    int bitsLeft = 0;

    for (int i = 0; i < cleanInput.length; i++) {
      int val = _base32Alphabet.indexOf(cleanInput[i]);
      if (val < 0) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bytes.add((buffer >> (bitsLeft - 8)) & 0xFF);
        bitsLeft -= 8;
      }
    }
    return bytes;
  }

  /// Generates a 6-digit TOTP code based on RFC 6238 / RFC 4226.
  static String generateTotp(String secret, {DateTime? time, int period = 30, int digits = 6}) {
    final now = time ?? DateTime.now();
    final epochSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final timeStep = epochSeconds ~/ period;

    // Convert timeStep into an 8-byte big-endian Uint8List
    final ByteData byteData = ByteData(8);
    byteData.setUint64(0, timeStep, Endian.big);
    final List<int> counterBytes = byteData.buffer.asUint8List();

    // Decode Base32 secret
    final List<int> secretBytes = _decodeBase32(secret);

    // Compute HMAC-SHA1
    final hmac = Hmac(sha1, secretBytes);
    final List<int> digest = hmac.convert(counterBytes).bytes;

    // Dynamic Truncation
    final int offset = digest.last & 0x0F;
    final int binaryCode = ((digest[offset] & 0x7F) << 24) |
        ((digest[offset + 1] & 0xFF) << 16) |
        ((digest[offset + 2] & 0xFF) << 8) |
        (digest[offset + 3] & 0xFF);

    final int otp = binaryCode % 1000000;
    return otp.toString().padLeft(digits, '0');
  }

  /// Verifies a TOTP code against a secret key with a window tolerance (±1 step for clock drift).
  static bool verifyTotp(String secret, String inputCode, {int timeWindowSteps = 1}) {
    final cleanCode = inputCode.trim();
    if (cleanCode.length != 6) return false;

    final now = DateTime.now();
    
    // Check current time step, previous (-1), and next (+1) step for clock skew
    for (int i = -timeWindowSteps; i <= timeWindowSteps; i++) {
      final testTime = now.add(Duration(seconds: i * 30));
      final generated = generateTotp(secret, time: testTime);
      if (generated == cleanCode) {
        return true;
      }
    }
    return false;
  }

  /// Generates the standard `otpauth://` URI used for Google Authenticator QR codes.
  static String generateKeyUri({
    required String username,
    required String secret,
    String issuer = 'FestAttendance',
  }) {
    final encodedUsername = Uri.encodeComponent(username);
    final encodedIssuer = Uri.encodeComponent(issuer);
    return 'otpauth://totp/$encodedIssuer:$encodedUsername?secret=$secret&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }
}
