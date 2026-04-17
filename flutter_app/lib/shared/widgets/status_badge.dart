import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.bgColor,
  });

  factory StatusBadge.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'paye':
      case 'disponible':
      case 'payée':
        return StatusBadge(label: status, color: AppColors.success, bgColor: AppColors.successBg);
      case 'en_retard':
      case 'impaye':
      case 'impayée':
      case 'expire':
      case 'vendu':
        return StatusBadge(label: status, color: AppColors.danger, bgColor: AppColors.dangerBg);
      case 'en_attente':
      case 'loue':
      case 'loué':
      case 'en_cours':
        return StatusBadge(label: status, color: AppColors.warning, bgColor: AppColors.warningBg);
      default:
        return StatusBadge(label: status, color: AppColors.textMuted, bgColor: AppColors.bgTertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    final bg = bgColor ?? AppColors.bgTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}
