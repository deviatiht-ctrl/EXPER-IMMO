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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0=role, 1=info, 2=verify
  String _selectedRole = '';
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _nationaliteCtrl = TextEditingController();
  final _pieceTypeCtrl = TextEditingController();
  final _pieceNumCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _employeurCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _adresseCtrl.dispose();
    _dobCtrl.dispose();
    _nationaliteCtrl.dispose();
    _pieceTypeCtrl.dispose();
    _pieceNumCtrl.dispose();
    _professionCtrl.dispose();
    _employeurCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      showAppToast(context, 'Les mots de passe ne correspondent pas', isError: true);
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      showAppToast(context, 'Le mot de passe doit contenir au moins 8 caractères', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _selectedRole,
        adresse: _adresseCtrl.text.trim(),
        dateNaissance: _dobCtrl.text.trim(),
        nationalite: _nationaliteCtrl.text.trim(),
        pieceType: _pieceTypeCtrl.text.trim(),
        pieceNumero: _pieceNumCtrl.text.trim(),
        profession: _professionCtrl.text.trim(),
        employeur: _employeurCtrl.text.trim(),
      );
      setState(() => _step = 2);
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
              const SizedBox(height: 32),
              const Center(child: AppLogo(size: 48)),
              const SizedBox(height: 24),
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 24),
              // Steps
              if (_step == 0) _buildRoleStep(),
              if (_step == 1) _buildInfoStep(),
              if (_step == 2) _buildVerifyStep(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(0, 'Profil'),
        _stepLine(0),
        _stepDot(1, 'Informations'),
        _stepLine(1),
        _stepDot(2, 'Vérification'),
      ],
    );
  }

  Widget _stepDot(int idx, String label) {
    final active = _step == idx;
    final done = _step > idx;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (active || done) ? AppColors.ruby : Colors.transparent,
            border: Border.all(color: (active || done) ? AppColors.ruby : AppColors.border, width: 2),
            boxShadow: active ? [BoxShadow(color: AppColors.ruby.withOpacity(0.15), blurRadius: 8)] : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('${idx + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textMuted)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppColors.ruby : AppColors.textMuted)),
      ],
    );
  }

  Widget _stepLine(int idx) {
    final done = _step > idx;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      color: done ? AppColors.ruby : AppColors.border,
    );
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisissez votre profil', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Sélectionnez le type de compte que vous souhaitez créer', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        _roleCard('proprietaire', Icons.home_work_outlined, 'Propriétaire', 'Je possède un ou plusieurs biens immobiliers'),
        const SizedBox(height: 12),
        _roleCard('locataire', Icons.person_outline, 'Locataire', 'Je suis locataire d\'un bien immobilier'),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Déjà un compte ?', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleCard(String role, IconData icon, String title, String subtitle) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _step = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppColors.rubyPale : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.ruby : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.ruby.withOpacity(0.1) : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? AppColors.ruby : AppColors.textMuted, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? AppColors.ruby : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: selected ? AppColors.ruby : AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step = 0)),
              Text('Vos informations', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(label: 'Nom complet', hint: 'Jean Dupont', controller: _nameCtrl, prefixIcon: Icons.person_outline, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
          const SizedBox(height: 14),
          AppTextField(label: 'Email', hint: 'nom@email.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.mail_outline, validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (!v.contains('@')) return 'Email invalide'; return null; }),
          const SizedBox(height: 14),
          AppTextField(label: 'Téléphone', hint: '+509 0000 0000', controller: _phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null),
          const SizedBox(height: 14),
          AppTextField(label: 'Adresse', hint: 'Votre adresse', controller: _adresseCtrl, prefixIcon: Icons.location_on_outlined),
          const SizedBox(height: 14),
          AppTextField(label: 'Nationalité', hint: 'Haïtienne', controller: _nationaliteCtrl, prefixIcon: Icons.flag_outlined),
          const SizedBox(height: 14),
          if (_selectedRole == 'locataire') ...[
            AppTextField(label: 'Profession', hint: 'Votre profession', controller: _professionCtrl, prefixIcon: Icons.work_outline),
            const SizedBox(height: 14),
            AppTextField(label: 'Employeur', hint: 'Nom de votre employeur', controller: _employeurCtrl, prefixIcon: Icons.business_outlined),
            const SizedBox(height: 14),
          ],
          AppTextField(
            label: 'Mot de passe',
            hint: '••••••••',
            controller: _passwordCtrl,
            obscureText: _obscure,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted), onPressed: () => setState(() => _obscure = !_obscure)),
            validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (v.length < 8) return '8 caractères minimum'; return null; },
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            validator: (v) { if (v != _passwordCtrl.text) return 'Ne correspond pas'; return null; },
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Créer mon compte', onPressed: _register, isLoading: _loading, icon: Icons.person_add, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text('Vérifiez votre email', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(
          'Un email de vérification a été envoyé à\n${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 32),
        AppButton(label: 'Retour à la connexion', onPressed: () => context.go('/login'), width: double.infinity),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            try {
              await ref.read(authNotifierProvider.notifier).resetPassword(_emailCtrl.text.trim());
              if (mounted) showAppToast(context, 'Email renvoyé!');
            } catch (e) {
              if (mounted) showAppToast(context, e.toString(), isError: true);
            }
          },
          child: const Text('Renvoyer l\'email'),
        ),
      ],
    );
  }
}
