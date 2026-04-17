import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/locataire_providers.dart';

class LocataireContratScreen extends ConsumerWidget {
  const LocataireContratScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contratAsync = ref.watch(locataireContratProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(locataireContratProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mon Contrat', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            contratAsync.when(
              loading: () => const LoadingWidget(message: 'Chargement du contrat...'),
              error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(locataireContratProvider)),
              data: (contrat) {
                if (contrat == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: EmptyStateWidget(icon: Icons.description_outlined, title: 'Aucun contrat actif', subtitle: 'Vous n\'avez pas de contrat en cours'),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Status header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.locataireColor, Color(0xFF047857)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Contrat actif', style: TextStyle(fontSize: 14, color: Colors.white70)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(100)),
                                child: Text(contrat['code_contrat'] ?? contrat['reference'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(formatCurrency(contrat['loyer_mensuel']), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                          const Text('/mois', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Contract details
                    _section('Détails du contrat', [
                      _row('Date de début', formatDate(contrat['date_debut']?.toString())),
                      _row('Date de fin', formatDate(contrat['date_fin']?.toString())),
                      _row('Signature', formatDate(contrat['date_signature']?.toString())),
                      _row('Modalité', contrat['modalite_paiement'] ?? '-'),
                      _row('Renouvellement auto', contrat['renouvellement_auto'] == true ? 'Oui' : 'Non'),
                      if (contrat['objet'] != null) _row('Objet', contrat['objet']),
                    ]),
                    const SizedBox(height: 12),
                    // Property info
                    _section('Bien loué', [
                      _row('Propriété', contrat['propriete']?['titre'] ?? '-'),
                      _row('Code', contrat['propriete']?['code_propriete'] ?? '-'),
                      _row('Adresse', contrat['propriete']?['adresse'] ?? '-'),
                      _row('Type', contrat['propriete']?['type_propriete'] ?? '-'),
                    ]),
                    const SizedBox(height: 12),
                    // Owner info
                    _section('Propriétaire', [
                      _row('Nom', contrat['proprietaire']?['user']?['full_name'] ?? '-'),
                      _row('Code', contrat['proprietaire']?['code_proprietaire'] ?? '-'),
                    ]),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.locataireColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
