import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 1 = kullanıcı adı + e-posta gir, 2 = kod + yeni şifre gir
  int _step = 1;
  bool _loading = false;
  String? _errorMessage;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (username.isEmpty || email.isEmpty) {
      setState(() => _errorMessage = 'Kullanıcı adı ve e-posta girin.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email}),
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _step = 2;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = body['error'] ?? 'Kod gönderilemedi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Sunucuya bağlanılamadı.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final username = _usernameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (code.isEmpty || newPassword.isEmpty) {
      setState(() => _errorMessage = 'Kod ve yeni şifre girin.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreniz güncellendi, giriş yapabilirsiniz.')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _loading = false;
          _errorMessage = body['error'] ?? 'Şifre güncellenemedi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Sunucuya bağlanılamadı.';
      });
    }
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textLight),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.lightBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _step == 1 ? 'Şifremi Unuttum' : 'Kodu Doğrula',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _step == 1
                      ? 'Kullanıcı adınızı ve e-posta adresinizi girin, size bir doğrulama kodu gönderelim.'
                      : 'E-postanıza gelen 6 haneli kodu ve yeni şifrenizi girin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _step == 1 ? _buildStepOne() : _buildStepTwo(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStepOne() {
    return [
      TextField(
        controller: _usernameCtrl,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        decoration: _decoration('Kullanıcı adı', Icons.person_outline),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendCode(),
        decoration: _decoration('E-posta adresi', Icons.email_outlined),
      ),
      if (_errorMessage != null) ..._errorBox(),
      const SizedBox(height: 20),
      _submitButton('Kod Gönder', _sendCode),
    ];
  }

  List<Widget> _buildStepTwo() {
    return [
      TextField(
        controller: _codeCtrl,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        decoration: _decoration('Doğrulama kodu', Icons.pin_outlined),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _newPasswordCtrl,
        obscureText: !_passwordVisible,
        textInputAction: TextInputAction.next,
        decoration: _decoration(
          'Yeni şifre',
          Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textLight,
            ),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _confirmPasswordCtrl,
        obscureText: !_passwordVisible,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _resetPassword(),
        decoration: _decoration('Yeni şifre (tekrar)', Icons.lock_outline),
      ),
      if (_errorMessage != null) ..._errorBox(),
      const SizedBox(height: 20),
      _submitButton('Şifreyi Güncelle', _resetPassword),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _loading ? null : () => setState(() => _step = 1),
        child: const Text('Kodu tekrar gönder', style: TextStyle(color: AppColors.primary)),
      ),
    ];
  }

  List<Widget> _errorBox() {
    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _submitButton(String label, Future<void> Function() onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}