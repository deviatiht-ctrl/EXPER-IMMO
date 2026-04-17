import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/locataire_providers.dart';

class LocataireProfilScreen extends ConsumerWidget {
  const LocataireProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(locataireProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(locataireProfileProvider)),
        data: (profile) {
          if (profile == null) return const EmptyStateWidget(icon: Icons.person_outline, title: 'Profil non trouvé');
          final name = profile['full_name'] ?? '';
          final email = profile['email'] ?? '';
          final phone = profile['phone'] ?? '';
          final role = profile['role'] ?? '';

          return Column(
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.locataireColor,
                child: Text(getInitials(name), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.locataireColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                child: Text(role.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.locataireColor)),
              ),
              const SizedBox(height: 24),
              _infoCard([
                _infoRow(Icons.mail_outline, 'Email', email),
                _infoRow(Icons.phone_outlined, 'Téléphone', phone),
                _infoRow(Icons.location_on_outlined, 'Adresse', profile['adresse'] ?? '-'),
                _infoRow(Icons.work_outline, 'Profession', profile['profession'] ?? '-'),
                _infoRow(Icons.business_outlined, 'Employeur', profile['employeur'] ?? '-'),
                _infoRow(Icons.calendar_today_outlined, 'Membre depuis', formatDate(profile['created_at']?.toString())),
              ]),
              const SizedBox(height: 16),
              _infoCard([
                _infoRow(Icons.badge_outlined, 'Pièce d\'identité', profile['piece_identite_type'] ?? '-'),
                _infoRow(Icons.numbers, 'N° pièce', profile['piece_identite_numero'] ?? '-'),
                _infoRow(Icons.flag_outlined, 'Nationalité', profile['nationalite'] ?? '-'),
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
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
