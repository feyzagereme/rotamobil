import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Ad soyad, kullanıcı adı ve şifre boş bırakılamaz.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalı.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor.');
      return;
    }

    setState(() => _errorMessage = null);

    // Kayıt endpoint'i backend'de henüz yok; şimdilik sadece arayüz.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kayıt özelliği yakında aktif olacak.'),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/icon/app_icon.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hesap Oluştur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sürücü hesabı için bilgilerinizi girin',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Form kartı
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Ad Soyad'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              hint: 'Adınızı ve soyadınızı girin',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _fieldLabel('Kullanıcı Adı'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameCtrl,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: _fieldDecoration(
                              hint: 'Bir kullanıcı adı belirleyin',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _fieldLabel('Telefon (opsiyonel)'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              hint: '05XX XXX XX XX',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _fieldLabel('Şifre'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: !_passwordVisible,
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDecoration(
                              hint: 'En az 6 karakter',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textLight,
                                ),
                                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _fieldLabel('Şifre Tekrar'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordCtrl,
                            obscureText: !_confirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: _fieldDecoration(
                              hint: 'Şifrenizi tekrar girin',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textLight,
                                ),
                                onPressed: () =>
                                    setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                              ),
                            ),
                          ),

                          if (_errorMessage != null) ...[
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
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Kayıt Ol',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Zaten hesabın var mı? Giriş Yap',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Geri butonu
            Positioned(
              top: 4,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.textLight),
      suffixIcon: suffixIcon,
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
}
