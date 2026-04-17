import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) showAppToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Center(child: AppLogo(size: 48)),
              const SizedBox(height: 40),
              if (!_sent) ...[
                Text('Mot de passe oublié ?', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Entrez votre email pour recevoir un lien de réinitialisation', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 32),
                AppTextField(label: 'Adresse email', hint: 'nom@exemple.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.mail_outline),
                const SizedBox(height: 24),
                AppButton(label: 'Envoyer le lien', onPressed: _send, isLoading: _loading, icon: Icons.send, width: double.infinity),
              ] else ...[
                const SizedBox(height: 20),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.success),
                ),
                const SizedBox(height: 24),
                Text('Email envoyé!', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('Vérifiez votre boîte de réception à\n${_emailCtrl.text}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.6)),
              ],
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Retour à la connexion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
