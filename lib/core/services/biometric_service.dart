import 'package:local_auth/local_auth.dart';

enum BiometricState {
  unauthenticated,
  authenticating,
  authenticated,
  failed,
}

class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on Exception {
      return false;
    }
  }

  Future<List<BiometricType>> checkBiometricTypes() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on Exception {
      return const [];
    }
  }

  Future<bool> authenticate({
    String localizedReason = 'Autenticacion requerida para acceder a LifeOS',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on Exception {
      return false;
    }
  }
}
