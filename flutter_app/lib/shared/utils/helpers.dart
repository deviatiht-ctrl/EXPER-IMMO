import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

/// Format a number as currency (HTG)
String formatCurrency(num? amount, {String currency = 'HTG'}) {
  if (amount == null) return '-';
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return '${formatter.format(amount)} $currency';
}

/// Format a date string (ISO) to dd/MM/yyyy
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

/// Format a date string to relative date
String formatRelativeDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

/// Show a snackbar toast
void showAppToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Get initials from a name
String getInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

/// Route path for a given role after login
String roleToRoute(String role) {
  switch (role.toLowerCase().trim()) {
    case 'admin':
    case 'assistante':
      return '/admin';
    case 'gestionnaire':
      return '/gestionnaire';
    case 'proprietaire':
      return '/proprietaire';
    case 'locataire':
    default:
      return '/locataire';
  }
}
