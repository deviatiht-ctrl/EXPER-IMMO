-- ============================================================
-- EXPER IMMO - ROW LEVEL SECURITY POLICIES
-- Secure Multi-tenant Access Control
-- ============================================================

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proprietaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locataires ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proprietes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contrats_location ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paiements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets_support ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rapports_proprietaire ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions_financieres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_systeme ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parametres ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_admin" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_all" ON public.profiles;

-- Users can read their own profile
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- Admin can read all profiles
CREATE POLICY "profiles_select_admin" ON public.profiles
    FOR SELECT USING (public.is_admin());

-- Users can update their own profile
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Admin can do everything
CREATE POLICY "profiles_admin_all" ON public.profiles
    FOR ALL USING (public.is_admin());

-- ============================================================
-- PROPRIETAIRES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "proprietaires_select_own" ON public.proprietaires;
DROP POLICY IF EXISTS "proprietaires_update_own" ON public.proprietaires;
DROP POLICY IF EXISTS "proprietaires_admin_all" ON public.proprietaires;

-- Proprietaires can read their own record
CREATE POLICY "proprietaires_select_own" ON public.proprietaires
    FOR SELECT USING (user_id = auth.uid());

-- Proprietaires can update their own record
CREATE POLICY "proprietaires_update_own" ON public.proprietaires
    FOR UPDATE USING (user_id = auth.uid());

-- Admin can do everything
CREATE POLICY "proprietaires_admin_all" ON public.proprietaires
    FOR ALL USING (public.is_admin());

-- ============================================================
-- LOCATAIRES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "locataires_select_own" ON public.locataires;
DROP POLICY IF EXISTS "locataires_update_own" ON public.locataires;
DROP POLICY IF EXISTS "locataires_admin_all" ON public.locataires;
DROP POLICY IF EXISTS "locataires_proprietaire_select" ON public.locataires;

-- Locataires can read their own record
CREATE POLICY "locataires_select_own" ON public.locataires
    FOR SELECT USING (user_id = auth.uid());

-- Locataires can update their own record
CREATE POLICY "locataires_update_own" ON public.locataires
    FOR UPDATE USING (user_id = auth.uid());

-- Admin can do everything
CREATE POLICY "locataires_admin_all" ON public.locataires
    FOR ALL USING (public.is_admin());

-- Proprietaires can see locataires of their properties
CREATE POLICY "locataires_proprietaire_select" ON public.locataires
    FOR SELECT USING (
        public.is_proprietaire() AND
        EXISTS (
            SELECT 1 FROM public.contrats_location c
            JOIN public.proprietaires p ON p.id = c.proprietaire_id
            WHERE c.locataire_id = locataires.id
            AND p.user_id = auth.uid()
        )
    );

-- ============================================================
-- AGENTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "agents_select_public" ON public.agents;
DROP POLICY IF EXISTS "agents_admin_all" ON public.agents;

-- Everyone can read active agents (public)
CREATE POLICY "agents_select_public" ON public.agents
    FOR SELECT USING (actif = TRUE OR public.is_admin());

-- Admin can do everything
CREATE POLICY "agents_admin_all" ON public.agents
    FOR ALL USING (public.is_admin());

-- ============================================================
-- ZONES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "zones_select_public" ON public.zones;
DROP POLICY IF EXISTS "zones_admin_all" ON public.zones;

-- Everyone can read active zones (public)
CREATE POLICY "zones_select_public" ON public.zones
    FOR SELECT USING (actif = TRUE OR public.is_admin());

-- Admin can do everything
CREATE POLICY "zones_admin_all" ON public.zones
    FOR ALL USING (public.is_admin());

-- ============================================================
-- PROPRIETES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "proprietes_select_public" ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_select_proprietaire" ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_select_locataire" ON public.proprietes;
DROP POLICY IF EXISTS "proprietes_admin_all" ON public.proprietes;

-- Public can read active available properties
CREATE POLICY "proprietes_select_public" ON public.proprietes
    FOR SELECT USING (est_actif = TRUE AND statut IN ('disponible', 'sous_compromis'));

-- Proprietaires can read all their properties
CREATE POLICY "proprietes_select_proprietaire" ON public.proprietes
    FOR SELECT USING (
        proprietaire_id = public.get_proprietaire_id()
    );

-- Locataires can read properties they rent
CREATE POLICY "proprietes_select_locataire" ON public.proprietes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.contrats_location c
            WHERE c.propriete_id = proprietes.id
            AND c.locataire_id = public.get_locataire_id()
            AND c.statut = 'actif'
        )
    );

-- Admin can do everything
CREATE POLICY "proprietes_admin_all" ON public.proprietes
    FOR ALL USING (public.is_admin());

-- ============================================================
-- CONTRATS_LOCATION POLICIES
-- ============================================================
DROP POLICY IF EXISTS "contrats_select_locataire" ON public.contrats_location;
DROP POLICY IF EXISTS "contrats_select_proprietaire" ON public.contrats_location;
DROP POLICY IF EXISTS "contrats_admin_all" ON public.contrats_location;

-- Locataires can read their contracts
CREATE POLICY "contrats_select_locataire" ON public.contrats_location
    FOR SELECT USING (locataire_id = public.get_locataire_id());

-- Proprietaires can read contracts for their properties
CREATE POLICY "contrats_select_proprietaire" ON public.contrats_location
    FOR SELECT USING (proprietaire_id = public.get_proprietaire_id());

-- Admin can do everything
CREATE POLICY "contrats_admin_all" ON public.contrats_location
    FOR ALL USING (public.is_admin());

-- ============================================================
-- PAIEMENTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "paiements_select_locataire" ON public.paiements;
DROP POLICY IF EXISTS "paiements_select_proprietaire" ON public.paiements;
DROP POLICY IF EXISTS "paiements_admin_all" ON public.paiements;

-- Locataires can read their payments
CREATE POLICY "paiements_select_locataire" ON public.paiements
    FOR SELECT USING (locataire_id = public.get_locataire_id());

-- Proprietaires can read payments for their properties
CREATE POLICY "paiements_select_proprietaire" ON public.paiements
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.contrats_location c
            WHERE c.id = paiements.contrat_id
            AND c.proprietaire_id = public.get_proprietaire_id()
        )
    );

-- Admin can do everything
CREATE POLICY "paiements_admin_all" ON public.paiements
    FOR ALL USING (public.is_admin());

-- ============================================================
-- TICKETS_SUPPORT POLICIES
-- ============================================================
DROP POLICY IF EXISTS "tickets_select_createur" ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_insert_locataire" ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_insert_proprietaire" ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_select_proprietaire" ON public.tickets_support;
DROP POLICY IF EXISTS "tickets_admin_all" ON public.tickets_support;

-- Users can read tickets they created
CREATE POLICY "tickets_select_createur" ON public.tickets_support
    FOR SELECT USING (createur_id = auth.uid());

-- Locataires can create tickets
CREATE POLICY "tickets_insert_locataire" ON public.tickets_support
    FOR INSERT WITH CHECK (
        public.is_locataire() AND createur_id = auth.uid()
    );

-- Proprietaires can create tickets
CREATE POLICY "tickets_insert_proprietaire" ON public.tickets_support
    FOR INSERT WITH CHECK (
        public.is_proprietaire() AND createur_id = auth.uid()
    );

-- Proprietaires can read tickets for their properties
CREATE POLICY "tickets_select_proprietaire" ON public.tickets_support
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.proprietes p
            WHERE p.id = tickets_support.propriete_id
            AND p.proprietaire_id = public.get_proprietaire_id()
        )
    );

-- Admin can do everything
CREATE POLICY "tickets_admin_all" ON public.tickets_support
    FOR ALL USING (public.is_admin());

-- ============================================================
-- TICKET_MESSAGES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "ticket_msg_select" ON public.ticket_messages;
DROP POLICY IF EXISTS "ticket_msg_insert" ON public.ticket_messages;
DROP POLICY IF EXISTS "ticket_msg_admin_all" ON public.ticket_messages;

-- Users can read messages on their tickets
CREATE POLICY "ticket_msg_select" ON public.ticket_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.tickets_support t
            WHERE t.id = ticket_messages.ticket_id
            AND (t.createur_id = auth.uid() OR public.is_admin())
        )
        AND (NOT est_interne OR public.is_admin())  -- Internal notes only for admin
    );

-- Users can add messages to their tickets
CREATE POLICY "ticket_msg_insert" ON public.ticket_messages
    FOR INSERT WITH CHECK (
        auteur_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.tickets_support t
            WHERE t.id = ticket_messages.ticket_id
            AND (t.createur_id = auth.uid() OR public.is_admin())
        )
    );

-- Admin can do everything
CREATE POLICY "ticket_msg_admin_all" ON public.ticket_messages
    FOR ALL USING (public.is_admin());

-- ============================================================
-- DOCUMENTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "documents_select_proprietaire" ON public.documents;
DROP POLICY IF EXISTS "documents_select_locataire" ON public.documents;
DROP POLICY IF EXISTS "documents_admin_all" ON public.documents;

-- Proprietaires can see their documents
CREATE POLICY "documents_select_proprietaire" ON public.documents
    FOR SELECT USING (
        visible_proprietaire = TRUE AND (
            proprietaire_id = public.get_proprietaire_id() OR
            EXISTS (
                SELECT 1 FROM public.proprietes p
                WHERE p.id = documents.propriete_id
                AND p.proprietaire_id = public.get_proprietaire_id()
            )
        )
    );

-- Locataires can see their documents
CREATE POLICY "documents_select_locataire" ON public.documents
    FOR SELECT USING (
        visible_locataire = TRUE AND (
            locataire_id = public.get_locataire_id() OR
            EXISTS (
                SELECT 1 FROM public.contrats_location c
                WHERE c.id = documents.contrat_id
                AND c.locataire_id = public.get_locataire_id()
            )
        )
    );

-- Admin can do everything
CREATE POLICY "documents_admin_all" ON public.documents
    FOR ALL USING (public.is_admin());

-- ============================================================
-- VISITES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "visites_select_proprietaire" ON public.visites;
DROP POLICY IF EXISTS "visites_admin_all" ON public.visites;
DROP POLICY IF EXISTS "visites_insert_public" ON public.visites;

-- Public can request visits
CREATE POLICY "visites_insert_public" ON public.visites
    FOR INSERT WITH CHECK (TRUE);

-- Proprietaires can see visits for their properties
CREATE POLICY "visites_select_proprietaire" ON public.visites
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.proprietes p
            WHERE p.id = visites.propriete_id
            AND p.proprietaire_id = public.get_proprietaire_id()
        )
    );

-- Admin can do everything
CREATE POLICY "visites_admin_all" ON public.visites
    FOR ALL USING (public.is_admin());

-- ============================================================
-- RAPPORTS_PROPRIETAIRE POLICIES
-- ============================================================
DROP POLICY IF EXISTS "rapports_select_proprietaire" ON public.rapports_proprietaire;
DROP POLICY IF EXISTS "rapports_admin_all" ON public.rapports_proprietaire;

-- Proprietaires can see their reports
CREATE POLICY "rapports_select_proprietaire" ON public.rapports_proprietaire
    FOR SELECT USING (proprietaire_id = public.get_proprietaire_id());

-- Admin can do everything
CREATE POLICY "rapports_admin_all" ON public.rapports_proprietaire
    FOR ALL USING (public.is_admin());

-- ============================================================
-- TRANSACTIONS_FINANCIERES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "transactions_select_proprietaire" ON public.transactions_financieres;
DROP POLICY IF EXISTS "transactions_select_locataire" ON public.transactions_financieres;
DROP POLICY IF EXISTS "transactions_admin_all" ON public.transactions_financieres;

-- Proprietaires can see their transactions
CREATE POLICY "transactions_select_proprietaire" ON public.transactions_financieres
    FOR SELECT USING (proprietaire_id = public.get_proprietaire_id());

-- Locataires can see their transactions
CREATE POLICY "transactions_select_locataire" ON public.transactions_financieres
    FOR SELECT USING (locataire_id = public.get_locataire_id());

-- Admin can do everything
CREATE POLICY "transactions_admin_all" ON public.transactions_financieres
    FOR ALL USING (public.is_admin());

-- ============================================================
-- AUDIT_LOG POLICIES (Admin only)
-- ============================================================
DROP POLICY IF EXISTS "audit_admin_only" ON public.audit_log;

CREATE POLICY "audit_admin_only" ON public.audit_log
    FOR ALL USING (public.is_admin());

-- ============================================================
-- NOTIFICATIONS_SYSTEME POLICIES
-- ============================================================
DROP POLICY IF EXISTS "notif_select_own" ON public.notifications_systeme;
DROP POLICY IF EXISTS "notif_update_own" ON public.notifications_systeme;
DROP POLICY IF EXISTS "notif_admin_all" ON public.notifications_systeme;

-- Users can read their notifications
CREATE POLICY "notif_select_own" ON public.notifications_systeme
    FOR SELECT USING (destinataire_id = auth.uid());

-- Users can update (mark as read) their notifications
CREATE POLICY "notif_update_own" ON public.notifications_systeme
    FOR UPDATE USING (destinataire_id = auth.uid());

-- Admin can do everything
CREATE POLICY "notif_admin_all" ON public.notifications_systeme
    FOR ALL USING (public.is_admin());

-- ============================================================
-- CONTACTS POLICIES
-- ============================================================
DROP POLICY IF EXISTS "contacts_insert_public" ON public.contacts;
DROP POLICY IF EXISTS "contacts_admin_all" ON public.contacts;

-- Anyone can submit contacts (public forms)
CREATE POLICY "contacts_insert_public" ON public.contacts
    FOR INSERT WITH CHECK (TRUE);

-- Admin can do everything
CREATE POLICY "contacts_admin_all" ON public.contacts
    FOR ALL USING (public.is_admin());

-- ============================================================
-- PARAMETRES POLICIES
-- ============================================================
DROP POLICY IF EXISTS "parametres_select_public" ON public.parametres;
DROP POLICY IF EXISTS "parametres_admin_all" ON public.parametres;

-- Everyone can read parameters
CREATE POLICY "parametres_select_public" ON public.parametres
    FOR SELECT USING (TRUE);

-- Admin can do everything
CREATE POLICY "parametres_admin_all" ON public.parametres
    FOR ALL USING (public.is_admin());
