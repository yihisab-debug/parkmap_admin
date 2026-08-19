import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogleAsAdmin();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 96, color: Colors.blue),
                const SizedBox(height: 12),
                const Text('ParkMap Админ',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Управление парковками и заявками',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 48),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Войти через Google'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
