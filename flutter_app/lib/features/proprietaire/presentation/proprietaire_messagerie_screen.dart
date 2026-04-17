import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/utils/helpers.dart';
import '../providers/proprietaire_providers.dart';

class ProprietaireMessagerieScreen extends ConsumerWidget {
  const ProprietaireMessagerieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(proprietaireMessagesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text('Messagerie', style: Theme.of(context).textTheme.headlineLarge)),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => ref.invalidate(proprietaireMessagesProvider)),
            ],
          ),
        ),
        Expanded(
          child: dataAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorRetryWidget(message: e.toString(), onRetry: () => ref.invalidate(proprietaireMessagesProvider)),
            data: (list) {
              if (list.isEmpty) return const EmptyStateWidget(icon: Icons.chat_outlined, title: 'Aucun message', subtitle: 'Vos conversations apparaîtront ici');
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(proprietaireMessagesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.proprietaireColor.withOpacity(0.1),
                            child: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.proprietaireColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['sujet'] ?? 'Sans sujet', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                if (m['contenu'] != null) Text(m['contenu'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Text(formatRelativeDate(m['created_at']?.toString()), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
