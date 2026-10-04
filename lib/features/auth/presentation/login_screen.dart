import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_switch_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getFirebaseErrorMessage(dynamic error, AppLocalizations l10n) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return l10n.errUserNotFound;
        case 'wrong-password':
          return l10n.errWrongPassword;
        case 'email-already-in-use':
          return l10n.errEmailInUse;
        case 'invalid-email':
          return l10n.errInvalidEmail;
        case 'weak-password':
          return l10n.errWeakPassword;
        case 'popup-closed-by-user':
          return l10n.errPopupClosed;
        case 'popup-blocked':
          return l10n.errPopupBlocked;
        default:
          return error.message ?? '${l10n.error} (${error.code})';
      }
    }
    return error.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    try {
      if (_isSignUp) {
        await ref.read(authRepositoryProvider).signUpWithEmail(
          email,
          password,
          fullName.isEmpty ? l10n.defaultUserName : fullName,
        );
      } else {
        await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getFirebaseErrorMessage(e, l10n)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToForgotPassword() {
    context.push('/forgot-password', extra: _emailController.text.trim());
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final l10n = context.l10n;
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errGoogleSignInPrefix}${_getFirebaseErrorMessage(e, l10n)}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language Switcher Pill at Top Right
                    const Align(
                      alignment: Alignment.topRight,
                      child: LanguagePillToggle(),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check_rounded, size: 38, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.appTextColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp ? l10n.createAccountToStart : l10n.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: context.appTextMutedColor),
                    ),
                    const SizedBox(height: 32),

                    // Toggle Tab Đăng nhập / Đăng ký
                    Container(
                      decoration: BoxDecoration(
                        color: context.subtleBgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.appBorderColor, width: 0.8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : () {
                                HapticFeedback.selectionClick();
                                setState(() => _isSignUp = false);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isSignUp ? context.cardBgColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isSignUp
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  l10n.login,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                                    color: !_isSignUp ? AppColors.accent : context.appTextMutedColor,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : () {
                                HapticFeedback.selectionClick();
                                setState(() => _isSignUp = true);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isSignUp ? context.cardBgColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isSignUp
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  l10n.signUp,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                                    color: _isSignUp ? AppColors.accent : context.appTextMutedColor,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Họ và tên (chỉ hiển thị khi Đăng ký)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.fullName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (val) {
                          if (!_isSignUp) return null;
                          if (val == null || val.trim().isEmpty) return l10n.errEnterName;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return l10n.errEnterEmail;
                        if (!val.contains('@') || !val.contains('.')) return l10n.errInvalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mật khẩu
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (val) {
                        if (val == null || val.isEmpty) return l10n.errEnterPassword;
                        if (val.length < 6) return l10n.errPasswordTooShort;
                        return null;
                      },
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _goToForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: TextStyle(color: context.appTextMutedColor, fontSize: 13),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Nhập lại mật khẩu (khi Đăng ký)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_reset),
                        ),
                        obscureText: _obscurePassword,
                        validator: (val) {
                          if (!_isSignUp) return null;
                          if (val != _passwordController.text) return l10n.errPasswordMismatch;
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 8),

                    // Nút Đăng nhập / Đăng ký chính
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isSignUp ? l10n.createAccountBtn : l10n.login,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Dòng kẻ "HOẶC"
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(l10n.orDivider, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nút Đăng nhập Google
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.login),
                      ),
                      label: Text(l10n.continueWithGoogle, style: const TextStyle(fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút chuyển đổi phụ
                    TextButton(
                      onPressed: _isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? l10n.alreadyHaveAccount
                            : l10n.dontHaveAccount,
                        style: const TextStyle(color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
