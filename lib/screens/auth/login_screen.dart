import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  String _error = '';
  bool _loading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final auth = context.read<AuthProvider>();
    final available = await auth.isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  void _appendDigit(String d) {
    if (_pin.length < 4) {
      setState(() {
        _pin += d;
        _error = '';
      });
      if (_pin.length == 4) _login();
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithPin(_pin);
    if (mounted) {
      if (!ok) {
        setState(() { _loading = false; _error = 'Invalid PIN. Try again.'; _pin = ''; });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fingerprintLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.loginWithFingerprint();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SALEISM PRO',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Wholesale Inventory Management',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 48),

                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? AppColors.primaryOrange : AppColors.border,
                      border: Border.all(
                        color: i < _pin.length ? AppColors.primaryOrange : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                  )),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 32),

                // Numpad
                ...['1 2 3', '4 5 6', '7 8 9'].map((row) {
                  final digits = row.split(' ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: digits.map((d) => _NumKey(
                        label: d,
                        onTap: () => _appendDigit(d),
                      )).toList(),
                    ),
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _biometricAvailable
                        ? _NumKey(
                            icon: Icons.fingerprint,
                            onTap: _fingerprintLogin,
                            color: AppColors.primaryOrange,
                          )
                        : const SizedBox(width: 80, height: 64),
                    _NumKey(label: '0', onTap: () => _appendDigit('0')),
                    _NumKey(icon: Icons.backspace_outlined, onTap: _backspace),
                  ],
                ),

                if (_loading) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppColors.primaryOrange),
                ],
                const SizedBox(height: 32),
                Text(
                  'Default PIN: 1234',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;

  const _NumKey({this.label, this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(label!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600))
            : Icon(icon!, color: color ?? AppColors.textSecondary, size: 26),
      ),
    );
  }
}
