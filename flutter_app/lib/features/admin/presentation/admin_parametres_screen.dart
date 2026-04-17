import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AdminParametresScreen extends ConsumerWidget {
  const AdminParametresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paramètres', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          const Text('Configuration de la plateforme', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 24),
          _section('Général', [
            _tile(Icons.business, 'Informations agence', 'Nom, adresse, contact', () {}),
            _tile(Icons.palette_outlined, 'Apparence', 'Thème et couleurs', () {}),
            _tile(Icons.language, 'Langue', 'Français', () {}),
          ]),
          const SizedBox(height: 16),
          _section('Finances', [
            _tile(Icons.attach_money, 'Devise par défaut', 'HTG (Gourde haïtienne)', () {}),
            _tile(Icons.receipt_long_outlined, 'Facturation', 'Paramètres des factures', () {}),
            _tile(Icons.percent, 'Commission', 'Taux de commission gestionnaire', () {}),
          ]),
          const SizedBox(height: 16),
          _section('Notifications', [
            _tile(Icons.notifications_outlined, 'Alertes email', 'Notifications par email', () {}),
            _tile(Icons.sms_outlined, 'Alertes SMS', 'Notifications par SMS', () {}),
          ]),
          const SizedBox(height: 16),
          _section('Sécurité', [
            _tile(Icons.lock_outline, 'Changer le mot de passe', '', () {}),
            _tile(Icons.security, 'Authentification 2FA', 'Non activée', () {}),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 22, color: AppColors.adminAccent),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      onTap: onTap,
      dense: true,
    );
  }
}
