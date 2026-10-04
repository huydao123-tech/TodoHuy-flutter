import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/auth_repository.dart';

/// Forgot-password recovery flow.
/// State 1: email input (pre-filled from login if available).
/// State 2: generic confirmation (does NOT reveal whether the email exists).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      // Never reveal whether the account exists — always show the confirmation.
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appTextColor),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          l10n.forgotPasswordTitle,
          style: TextStyle(color: context.appTextColor, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _sent ? _buildConfirmation(l10n) : _buildInput(l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 56, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            l10n.resetPassword,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.appTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.resetPasswordInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.appTextMutedColor, height: 1.5),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _sendResetEmail(),
            decoration: InputDecoration(
              labelText: l10n.email,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.email_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.errEnterEmail;
              if (!val.contains('@') || !val.contains('.')) return l10n.errInvalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    l10n.sendResetLink,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.checkYourEmail,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.appTextColor),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.resetConfirmationDesc,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.appTextMutedColor, height: 1.6),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            l10n.resend,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            l10n.backToLogin,
            style: const TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
