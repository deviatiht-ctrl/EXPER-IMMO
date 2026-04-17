import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietaireDocumentsScreen extends ConsumerWidget {
  const ProprietaireDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(proprietaireDocumentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Documents', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(proprietaireDocumentsProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietaireDocumentsProvider)),
            data: (list) {
              if (list.isEmpty) return const EmptyStateWidget(icon: Icons.folder_outlined, title: 'Aucun document', subtitle: 'Vos documents apparaîtront ici');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(proprietaireDocumentsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = list[i];
                    final type = d['type_document'] ?? '-';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: AppColors.adminInfo.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.insert_drive_file_outlined, size: 20, color: AppColors.adminInfo),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['nom'] ?? d['titre'] ?? 'Document', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('$type · ${formatRelativeDate(d['created_at']?.toString())}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.download_outlined, size: 20, color: AppColors.proprietaireColor), onPressed: () {}),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
