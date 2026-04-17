import 'package:flutter/material.dart';

/// Brand colors extracted from EXPERIMMO web app CSS variables
class AppColors {
  AppColors._();

  // Core Brand
  static const Color ruby = Color(0xFFC41E3A);
  static const Color rubyDark = Color(0xFF8B1529);
  static const Color rubyLight = Color(0xFFE02F4F);
  static const Color rubyPale = Color(0xFFFFF5F6);

  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color charcoalDark = Color(0xFF1A1A1A);
  static const Color charcoalLight = Color(0xFF4A4A4A);
  static const Color charcoalPale = Color(0xFFF5F5F5);

  // Functional
  static const Color primary = ruby;
  static const Color primaryDark = rubyDark;
  static const Color secondary = charcoal;

  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFEADDB6);
  static const Color navy = Color(0xFF0F172A);

  // Backgrounds
  static const Color bgMain = Color(0xFFFDFDFD);
  static const Color bgSecondary = Color(0xFFF7F7F7);
  static const Color bgTertiary = Color(0xFFEFEFEF);
  static const Color bgDark = Color(0xFF121212);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textMuted = Color(0xFF777777);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderFocus = ruby;

  // Status
  static const Color success = Color(0xFF00875A);
  static const Color successBg = Color(0xFFE3FCEF);
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningBg = Color(0xFFFFF0B3);
  static const Color danger = Color(0xFFDE350B);
  static const Color dangerBg = Color(0xFFFFEBE6);

  // Property status
  static const Color statutDisponible = Color(0xFF00875A);
  static const Color statutCompromis = Color(0xFFFFAB00);
  static const Color statutVendu = Color(0xFFDE350B);
  static const Color statutLoue = Color(0xFF6554C0);

  // Admin panel
  static const Color adminBg = Color(0xFFF1F5F9);
  static const Color adminSidebar = Color(0xFF0D1B2A);
  static const Color adminAccent = Color(0xFFC53636);
  static const Color adminSuccess = Color(0xFF10B981);
  static const Color adminWarning = Color(0xFFF59E0B);
  static const Color adminInfo = Color(0xFF3B82F6);
  static const Color adminPurple = Color(0xFF8B5CF6);

  // Portal role colors
  static const Color proprietaireColor = Color(0xFF1B4FBB);
  static const Color locataireColor = Color(0xFF059669);
  static const Color gestionnaireColor = Color(0xFF7C3AED);
  static const Color adminColor = Color(0xFF8B1538);
}
