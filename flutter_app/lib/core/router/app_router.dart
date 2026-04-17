import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/splash/presentation/splash_screen.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_proprietaires_screen.dart';
import '../../features/admin/presentation/admin_locataires_screen.dart';
import '../../features/admin/presentation/admin_proprietes_screen.dart';
import '../../features/admin/presentation/admin_contrats_screen.dart';
import '../../features/admin/presentation/admin_paiements_screen.dart';
import '../../features/admin/presentation/admin_factures_screen.dart';
import '../../features/admin/presentation/admin_operations_screen.dart';
import '../../features/admin/presentation/admin_statistiques_screen.dart';
import '../../features/admin/presentation/admin_messages_screen.dart';
import '../../features/admin/presentation/admin_parametres_screen.dart';

import '../../features/proprietaire/presentation/proprietaire_shell.dart';
import '../../features/proprietaire/presentation/proprietaire_dashboard_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_proprietes_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_contrats_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_paiements_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_operations_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_messagerie_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_documents_screen.dart';
import '../../features/proprietaire/presentation/proprietaire_profil_screen.dart';

import '../../features/locataire/presentation/locataire_shell.dart';
import '../../features/locataire/presentation/locataire_dashboard_screen.dart';
import '../../features/locataire/presentation/locataire_contrat_screen.dart';
import '../../features/locataire/presentation/locataire_paiements_screen.dart';
import '../../features/locataire/presentation/locataire_factures_screen.dart';
import '../../features/locataire/presentation/locataire_echeances_screen.dart';
import '../../features/locataire/presentation/locataire_messagerie_screen.dart';
import '../../features/locataire/presentation/locataire_documents_screen.dart';
import '../../features/locataire/presentation/locataire_profil_screen.dart';

import '../../features/gestionnaire/presentation/gestionnaire_shell.dart';
import '../../features/gestionnaire/presentation/gestionnaire_dashboard_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_locataires_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_biens_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_contrats_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_operations_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_proprietaires_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_messages_screen.dart';
import '../../features/gestionnaire/presentation/gestionnaire_documents_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ── ADMIN ──
      ShellRoute(
        builder: (_, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/proprietaires', builder: (_, __) => const AdminProprietairesScreen()),
          GoRoute(path: '/admin/locataires', builder: (_, __) => const AdminLocatairesScreen()),
          GoRoute(path: '/admin/proprietes', builder: (_, __) => const AdminProprietesScreen()),
          GoRoute(path: '/admin/contrats', builder: (_, __) => const AdminContratsScreen()),
          GoRoute(path: '/admin/paiements', builder: (_, __) => const AdminPaiementsScreen()),
          GoRoute(path: '/admin/factures', builder: (_, __) => const AdminFacturesScreen()),
          GoRoute(path: '/admin/operations', builder: (_, __) => const AdminOperationsScreen()),
          GoRoute(path: '/admin/statistiques', builder: (_, __) => const AdminStatistiquesScreen()),
          GoRoute(path: '/admin/messages', builder: (_, __) => const AdminMessagesScreen()),
          GoRoute(path: '/admin/parametres', builder: (_, __) => const AdminParametresScreen()),
        ],
      ),

      // ── PROPRIETAIRE ──
      ShellRoute(
        builder: (_, state, child) => ProprietaireShell(child: child),
        routes: [
          GoRoute(path: '/proprietaire', builder: (_, __) => const ProprietaireDashboardScreen()),
          GoRoute(path: '/proprietaire/proprietes', builder: (_, __) => const ProprietaireProprietesScreen()),
          GoRoute(path: '/proprietaire/contrats', builder: (_, __) => const ProprietaireContratsScreen()),
          GoRoute(path: '/proprietaire/paiements', builder: (_, __) => const ProprietairePaiementsScreen()),
          GoRoute(path: '/proprietaire/operations', builder: (_, __) => const ProprietaireOperationsScreen()),
          GoRoute(path: '/proprietaire/messagerie', builder: (_, __) => const ProprietaireMessagerieScreen()),
          GoRoute(path: '/proprietaire/documents', builder: (_, __) => const ProprietaireDocumentsScreen()),
          GoRoute(path: '/proprietaire/profil', builder: (_, __) => const ProprietaireProfilScreen()),
        ],
      ),

      // ── LOCATAIRE ──
      ShellRoute(
        builder: (_, state, child) => LocataireShell(child: child),
        routes: [
          GoRoute(path: '/locataire', builder: (_, __) => const LocataireDashboardScreen()),
          GoRoute(path: '/locataire/contrat', builder: (_, __) => const LocataireContratScreen()),
          GoRoute(path: '/locataire/paiements', builder: (_, __) => const LocatairePaiementsScreen()),
          GoRoute(path: '/locataire/factures', builder: (_, __) => const LocataireFacturesScreen()),
          GoRoute(path: '/locataire/echeances', builder: (_, __) => const LocataireEcheancesScreen()),
          GoRoute(path: '/locataire/messagerie', builder: (_, __) => const LocataireMessagerieScreen()),
          GoRoute(path: '/locataire/documents', builder: (_, __) => const LocataireDocumentsScreen()),
          GoRoute(path: '/locataire/profil', builder: (_, __) => const LocataireProfilScreen()),
        ],
      ),

      // ── GESTIONNAIRE ──
      ShellRoute(
        builder: (_, state, child) => GestionnaireShell(child: child),
        routes: [
          GoRoute(path: '/gestionnaire', builder: (_, __) => const GestionnaireDashboardScreen()),
          GoRoute(path: '/gestionnaire/locataires', builder: (_, __) => const GestionnaireLocatairesScreen()),
          GoRoute(path: '/gestionnaire/biens', builder: (_, __) => const GestionnaireBiensScreen()),
          GoRoute(path: '/gestionnaire/contrats', builder: (_, __) => const GestionnaireContratsScreen()),
          GoRoute(path: '/gestionnaire/operations', builder: (_, __) => const GestionnaireOperationsScreen()),
          GoRoute(path: '/gestionnaire/proprietaires', builder: (_, __) => const GestionnaireProprietairesScreen()),
          GoRoute(path: '/gestionnaire/messages', builder: (_, __) => const GestionnaireMessagesScreen()),
          GoRoute(path: '/gestionnaire/documents', builder: (_, __) => const GestionnaireDocumentsScreen()),
        ],
      ),
    ],
  );
});
