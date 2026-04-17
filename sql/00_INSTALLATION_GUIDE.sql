-- ============================================================
--      EXPER IMMO - MASTER DATABASE INSTALLATION
--      Complete Multi-Tenant Real Estate Management System
-- ============================================================
-- 
-- INSTALLATION ORDER:
-- 1. Run this file in Supabase SQL Editor
-- 2. Or run individual files in order: 06, 07, 08, 09
--
-- SYSTEM OVERVIEW:
-- ================
-- 3 User Types with different access levels:
-- 
-- 1. ADMIN (Expert Immo Staff)
--    - Full access to everything
--    - Manage all properties, contracts, payments
--    - View audit logs and financial reports
--    - Create/manage proprietaires and locataires
--
-- 2. PROPRIETAIRE (Property Owner)
--    - View their own properties
--    - See contracts and payments for their properties
--    - Access monthly financial reports
--    - View tenant information (limited)
--    - Create support tickets
--
-- 3. LOCATAIRE (Tenant)
--    - View their rental contract
--    - See payment history and upcoming payments
--    - Create support tickets (maintenance, etc.)
--    - Update their profile information
--
-- ============================================================
-- DATABASE TABLES:
-- ============================================================
-- 
-- USER MANAGEMENT:
-- - profiles          : Extended user profiles (all roles)
-- - proprietaires     : Property owner specific data
-- - locataires        : Tenant specific data
-- 
-- PROPERTY MANAGEMENT:
-- - proprietes        : Properties (enhanced with owner link)
-- - zones             : Geographic areas
-- - agents            : Real estate agents
-- 
-- RENTAL MANAGEMENT:
-- - contrats_location : Rental contracts
-- - paiements         : Payment records
-- - visites           : Property visits
-- 
-- SUPPORT & COMMUNICATION:
-- - tickets_support   : Support tickets/complaints
-- - ticket_messages   : Ticket conversations
-- - notifications_systeme : System notifications
-- - contacts          : Contact form submissions
-- 
-- DOCUMENTS & FINANCE:
-- - documents         : Document management
-- - rapports_proprietaire : Owner reports
-- - transactions_financieres : Financial ledger
-- 
-- SECURITY:
-- - audit_log         : Audit trail for sensitive operations
-- - parametres        : System configuration
--
-- ============================================================
-- SECURITY FEATURES:
-- ============================================================
-- 
-- 1. Row Level Security (RLS) on ALL tables
-- 2. Role-based access control
-- 3. Audit logging for sensitive operations
-- 4. Data isolation between proprietaires/locataires
-- 5. Encrypted sensitive data (handled by Supabase)
-- 6. Session management via Supabase Auth
--
-- ============================================================
-- HOW TO USE:
-- ============================================================
-- 
-- 1. User Signup (Frontend):
--    - User signs up with Supabase Auth
--    - Pass role in user_metadata: { role: 'proprietaire' }
--    - Trigger auto-creates profile and role-specific record
--
-- 2. Admin Dashboard:
--    - Call: get_admin_dashboard_stats()
--    - Manage all users, properties, contracts
--
-- 3. Proprietaire Portal:
--    - Call: get_proprietaire_dashboard(proprietaire_id)
--    - View properties, contracts, payments
--
-- 4. Locataire Portal:
--    - Call: get_locataire_dashboard(locataire_id)
--    - View contract, payments, create tickets
--
-- ============================================================

-- Run individual files in order:
-- \i '06_complete_schema.sql'
-- \i '07_functions_triggers.sql'
-- \i '08_rls_policies.sql'
-- \i '09_seed_data.sql'

-- ============================================================
-- QUICK START: Create first admin user
-- ============================================================
-- After creating user via Supabase Auth, run:
/*

-- Make user an admin
UPDATE public.profiles 
SET role = 'admin', is_verified = TRUE 
WHERE email = 'your-admin@email.com';

*/

-- ============================================================
-- USEFUL QUERIES FOR ADMIN:
-- ============================================================

-- Get dashboard stats
-- SELECT * FROM public.get_admin_dashboard_stats();

-- Get all active contracts
-- SELECT * FROM public.contrats_location WHERE statut = 'actif';

-- Get late payments
-- SELECT * FROM public.paiements WHERE statut = 'en_retard';

-- Get open tickets
-- SELECT * FROM public.tickets_support WHERE statut IN ('ouvert', 'en_cours');

-- ============================================================
-- SCHEDULED JOBS (Set up in Supabase):
-- ============================================================

-- Run daily to check late payments:
-- SELECT public.check_paiements_retard();

-- Run monthly to generate next month's payments:
-- SELECT public.generer_paiements_mensuels();

-- ============================================================
-- END OF INSTALLATION GUIDE
-- ============================================================
