import 'package:flutter_test/flutter_test.dart';
import 'package:drivio/utils/auth_error_message.dart';

void main() {
  group('authentication errors', () {
    test('recognizes provider cancellation without showing an error', () {
      expect(isAuthCancellation(Exception('canceled')), isTrue);
      expect(isAuthCancellation(Exception('popup-closed-by-user')), isTrue);
      expect(isAuthCancellation(Exception('network-request-failed')), isFalse);
    });

    test('maps actionable Firebase provider errors', () {
      expect(
        authErrorMessage(Exception('invalid-credential'), providerLogin: true),
        contains('dostawcy'),
      );
      expect(
        authErrorMessage(Exception('operation-not-allowed')),
        contains('Firebase'),
      );
      expect(
        authErrorMessage(Exception('account-exists-with-different-credential')),
        contains('innego dostawcy'),
      );
      expect(
        authErrorMessage(Exception('network-request-failed')),
        contains('internetem'),
      );
    });
  });
}
