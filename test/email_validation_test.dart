import 'package:flutter_test/flutter_test.dart';

// Test email validation regex
void main() {
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  group('Email Validation Tests', () {
    test('Valid emails should pass', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'test+tag@gmail.com',
        'user@subdomain.domain.org',
        'test@domain.technology', // Long TLD
        'user_name@domain.com',
      ];

      for (final email in validEmails) {
        expect(emailRegex.hasMatch(email.trim()), true, reason: '$email should be valid');
      }
    });

    test('Invalid emails should fail', () {
      final invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user@domain',
        '',
        '   ',
      ];

      for (final email in invalidEmails) {
        expect(emailRegex.hasMatch(email.trim()), false, reason: '$email should be invalid');
      }
    });

    test('Edge cases', () {
      // Test trimming
      expect(emailRegex.hasMatch('  test@example.com  '.trim()), true);
      expect(emailRegex.hasMatch('test@example.com'), true);
    });
  });
}
