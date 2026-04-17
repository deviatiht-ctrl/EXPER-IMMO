-- ============================================================
-- EXPER IMMO - SQL EXECUTION ORDER
-- Ordre d'exécution des fichiers SQL pour Supabase
-- ============================================================

/*
⚠️ INSTRUCTIONS IMPORTANTES:
============================
1. Connectez-vous à votre projet Supabase
2. Allez dans "SQL Editor" 
3. Créez une "New query" pour chaque fichier
4. Exécutez les fichiers DANS L'ORDRE indiqué ci-dessous
5. Attendez que chaque fichier termine avant de passer au suivant

⚠️ NE PAS SAUTER D'ÉTAPES - L'ordre est crucial!
*/

-- ============================================================
-- ÉTAPE 1: EXTENSIONS (01_extensions.sql)
-- ============================================================
-- À exécuter en PREMIER
-- Active les extensions PostgreSQL nécessaires

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ============================================================
-- ÉTAPE 2: SCHÉMA DE BASE (02_schema.sql)
-- ============================================================
-- Tables de base: profiles, agents, zones, proprietes, contacts
-- NE PAS exécuter 06_complete_schema.sql à cette étape!

-- Tables créées:
-- - profiles (utilisateurs)
-- - agents (agents immobiliers)
-- - zones (zones géographiques)
-- - proprietes (biens immobiliers)
-- - contacts (formulaire de contact)
-- - notifications
-- - parametres

-- ============================================================
-- ÉTAPE 3: FONCTIONS DE BASE (03_functions_triggers.sql)
-- ============================================================
-- Fonctions essentielles pour le site public

-- Fonctions créées:
-- - handle_new_user() : Création auto de profil à l'inscription
-- - generer_reference() : Génération auto des références propriétés
-- - set_updated_at() : Mise à jour auto des timestamps
-- - notifier_contact() : Notifications sur nouveaux contacts
-- - incrementer_vues() : Incrémentation du compteur de vues
-- - rechercher_proprietes() : Recherche avancée de propriétés
-- - get_dashboard_stats() : Statistiques admin dashboard

-- ============================================================
-- ÉTAPE 4: POLITIQUES RLS DE BASE (04_rls_policies.sql)
-- ============================================================
-- Sécurité de base pour les tables publiques

-- Policies pour:
-- - profiles
-- - agents
-- - zones
-- - proprietes
-- - contacts
-- - notifications
-- - parametres

-- ============================================================
-- ÉTAPE 5: DONNÉES DE TEST (05_seed_data.sql)
-- ============================================================
-- Optionnel: Données de test pour le développement
-- Contient des agents et propriétés d'exemple

-- ============================================================
-- ⚠️ ÉTAPE 6: SCHÉMA COMPLET MULTI-TENANT (06_complete_schema.sql)
-- ============================================================
-- ⚠️ IMPORTANT: N'exécutez PAS si vous avez déjà exécuté 02_schema.sql
-- Ce fichier étend le schéma avec les tables pour propriétaires et locataires

-- Tables créées:
-- - proprietaires (infos propriétaires)
-- - locataires (infos locataires)
-- - contrats_location (contrats de location)
-- - paiements (paiements de loyer)
-- - tickets_support (tickets de support)
-- - ticket_messages (messages des tickets)
-- - documents (gestion de documents)
-- - visites (visites de propriétés)
-- - rapports_proprietaire (rapports mensuels)
-- - transactions_financieres (transactions)
-- - audit_log (journal d'audit)
-- - notifications_systeme (notifications)

-- ============================================================
-- ÉTAPE 7: FONCTIONS MULTI-TENANT (07_functions_triggers.sql)
-- ============================================================
-- Fonctions pour le système propriétaire/locataire

-- Fonctions créées:
-- - is_admin(), is_proprietaire(), is_locataire() : Vérification des rôles
-- - get_proprietaire_id(), get_locataire_id() : Récupération des IDs
-- - generer_reference_contrat() : Références contrats
-- - generer_reference_paiement() : Références paiements
-- - generer_reference_ticket() : Références tickets
-- - generer_reference_transaction() : Références transactions
-- - notifier_paiement() : Notifications de paiement
-- - notifier_nouveau_ticket() : Notifications tickets
-- - log_audit() : Journal d'audit
-- - check_paiements_retard() : Détection des retards
-- - get_admin_dashboard_stats() : Stats admin avancées
-- - get_proprietaire_dashboard() : Dashboard propriétaire
-- - get_locataire_dashboard() : Dashboard locataire
-- - generer_paiements_mensuels() : Génération auto des paiements

-- ============================================================
-- ÉTAPE 8: POLITIQUES RLS MULTI-TENANT (08_rls_policies.sql)
-- ============================================================
-- Sécurité avancée pour le multi-tenant

-- Policies pour:
-- - profiles (mise à jour avec rôles)
-- - proprietaires (accès propriétaire uniquement)
-- - locataires (accès locataire uniquement)
-- - contrats_location
-- - paiements
-- - tickets_support
-- - ticket_messages
-- - documents
-- - visites
-- - rapports_proprietaire
-- - transactions_financieres
-- - audit_log
-- - notifications_systeme

-- ============================================================
-- ÉTAPE 9: CONFIGURATION (09_seed_data.sql)
-- ============================================================
-- Données de configuration et templates

-- Insertions:
-- - Templates de notifications
-- - Options de catégories
-- - Règles métier (commission, dépôt de garantie, etc.)

-- ============================================================
-- RÉSUMÉ DE L'ORDRE D'EXÉCUTION
-- ============================================================

/*
POUR UN NOUVEAU PROJET (installation complète):
===============================================
1. 01_extensions.sql
2. 02_schema.sql
3. 03_functions_triggers.sql
4. 04_rls_policies.sql
5. 05_seed_data.sql (optionnel)
6. 06_complete_schema.sql
7. 07_functions_triggers.sql
8. 08_rls_policies.sql
9. 09_seed_data.sql

POUR UN PROJET EXISTANT (mise à jour):
======================================
Si vous avez déjà les tables de base (02_schema.sql exécuté):
1. 06_complete_schema.sql (ajoute les nouvelles tables)
2. 07_functions_triggers.sql
3. 08_rls_policies.sql
4. 09_seed_data.sql

⚠️ ATTENTION: Ne pas exécuter 02_schema.sql si les tables existent déjà!
*/

-- ============================================================
-- VÉRIFICATION APRÈS INSTALLATION
-- ============================================================

-- Exécutez ces requêtes pour vérifier que tout est OK:

-- 1. Vérifier les extensions
-- SELECT * FROM pg_extension WHERE extname IN ('uuid-ossp', 'pgcrypto', 'unaccent');

-- 2. Vérifier les tables
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- 3. Vérifier les fonctions
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' ORDER BY routine_name;

-- 4. Vérifier les triggers
-- SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public';

-- 5. Tester une fonction
-- SELECT * FROM get_dashboard_stats();

-- ============================================================
-- CRÉATION DU PREMIER ADMIN
-- ============================================================

/*
Après l'installation, créez un utilisateur admin:

1. Inscrivez-vous via l'interface web (inscription.html)
2. Puis exécutez dans SQL Editor:

UPDATE public.profiles 
SET role = 'admin', is_verified = TRUE 
WHERE email = 'votre-email@exemple.com';

3. Déconnectez-vous et reconnectez-vous
*/

-- ============================================================
-- JOBS PLANIFIÉS (À CONFIGURER DANS SUPABASE)
-- ============================================================

/*
Dans Supabase Dashboard > Database > Cron Jobs:

1. Vérification des paiements en retard (tous les jours à 8h):
   SELECT cron.schedule('check-late-payments', '0 8 * * *', 'SELECT check_paiements_retard()');

2. Génération des paiements mensuels (1er de chaque mois à 6h):
   SELECT cron.schedule('generate-monthly-payments', '0 6 1 * *', 'SELECT generer_paiements_mensuels()');
*/
