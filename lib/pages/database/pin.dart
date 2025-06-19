import 'package:local_auth/local_auth.dart';

class VaultSecurityManager {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Authenticate using fingerprint/biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) return false;

      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the vault',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  /// Verify PIN
  Future<bool> verifyPin(String enteredPin, String savedPin) async {
    return enteredPin == savedPin;
  }
}
