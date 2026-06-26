import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../core/database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  String get userName => _currentUser?['name'] ?? 'User';
  String get userRole => _currentUser?['role'] ?? 'staff';

  Future<bool> loginWithPin(String pin) async {
    final user = await DatabaseHelper.instance.validateUser(pin);
    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithFingerprint() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to login to SALEISM PRO',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        final db = DatabaseHelper.instance;
        final users = await db.getUsers();
        final adminUsers = users.where((u) => u['role'] == 'admin' && u['fingerprint_enabled'] == 1).toList();
        if (adminUsers.isNotEmpty) {
          _currentUser = adminUsers.first;
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
