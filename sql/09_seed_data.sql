-- ============================================================
-- EXPER IMMO - SEED DATA FOR TESTING
-- Sample data for multi-tenant system
-- ============================================================

-- NOTE: In production, users are created through Supabase Auth
-- This seed data is for development/testing purposes

-- ============================================================
-- CREATE TEST ADMIN USER
-- ============================================================
-- First, create a test admin in auth.users (for testing only)
-- In production, use Supabase Auth signup

-- After creating auth user, update profile to admin
UPDATE public.profiles 
SET role = 'admin', is_verified = TRUE 
WHERE email = 'laurorejeanclarens0@gmail.com';

-- ============================================================
-- SAMPLE PROPRIETAIRES (After auth signup)
-- ============================================================
-- These would be created after user signs up with role='proprietaire'

-- Example proprietaire data to update after signup:
/*
UPDATE public.proprietaires 
SET 
    type_proprietaire = 'particulier',
    nom_banque = 'BNC Haiti',
    numero_compte = 'XXXX-XXXX-1234',
    mode_paiement_prefere = 'virement',
    commission_taux = 10.00,
    date_debut_mandat = CURRENT_DATE,
    date_fin_mandat = CURRENT_DATE + INTERVAL '1 year',
    notification_whatsapp = TRUE
WHERE user_id = 'USER_UUID_HERE';
*/

-- ============================================================
-- SAMPLE LOCATAIRES (After auth signup)
-- ============================================================
-- These would be created after user signs up with role='locataire'

-- Example locataire data to update after signup:
/*
UPDATE public.locataires
SET 
    profession = 'Ingénieur',
    employeur = 'Digicel Haiti',
    revenu_mensuel = 3500.00,
    garant_nom = 'Jean Marie',
    garant_telephone = '+509 3800-0000',
    score_paiement = 100
WHERE user_id = 'USER_UUID_HERE';
*/

-- ============================================================
-- LINK EXISTING PROPERTIES TO PROPRIETAIRES
-- ============================================================
-- After proprietaires are created, link properties:
/*
UPDATE public.proprietes
SET 
    proprietaire_id = (SELECT id FROM public.proprietaires LIMIT 1),
    est_gere = TRUE
WHERE proprietaire_id IS NULL;
*/

-- ============================================================
-- SAMPLE CONTRACT
-- ============================================================
/*
INSERT INTO public.contrats_location (
    propriete_id,
    locataire_id,
    proprietaire_id,
    agent_id,
    date_debut,
    date_fin,
    loyer_mensuel,
    devise,
    charges_mensuelles,
    depot_garantie,
    depot_garantie_paye,
    jour_paiement,
    mode_paiement,
    statut,
    renouvellement_auto
) VALUES (
    'PROPERTY_UUID',
    'LOCATAIRE_UUID',
    'PROPRIETAIRE_UUID',
    'AGENT_UUID',
    '2024-01-01',
    '2025-01-01',
    1800.00,
    'USD',
    100.00,
    3600.00,  -- 2 months deposit
    TRUE,
    5,  -- Payment due on 5th
    'virement',
    'actif',
    TRUE
);
*/

-- ============================================================
-- SAMPLE PAYMENTS (Generated monthly)
-- ============================================================
/*
INSERT INTO public.paiements (
    contrat_id,
    locataire_id,
    propriete_id,
    mois,
    annee,
    periode_debut,
    periode_fin,
    montant_loyer,
    montant_charges,
    montant_total,
    date_echeance,
    date_paiement,
    montant_paye,
    statut,
    mode_paiement,
    devise
) VALUES (
    'CONTRAT_UUID',
    'LOCATAIRE_UUID',
    'PROPRIETE_UUID',
    3,  -- March
    2024,
    '2024-03-01',
    '2024-03-31',
    1800.00,
    100.00,
    1900.00,
    '2024-03-05',
    '2024-03-03',
    1900.00,
    'paye',
    'virement',
    'USD'
);
*/

-- ============================================================
-- SAMPLE TICKET
-- ============================================================
/*
INSERT INTO public.tickets_support (
    createur_id,
    type_createur,
    propriete_id,
    contrat_id,
    sujet,
    description,
    categorie,
    priorite,
    statut
) VALUES (
    'USER_UUID',
    'locataire',
    'PROPRIETE_UUID',
    'CONTRAT_UUID',
    'Problème de plomberie - Salle de bain',
    'La douche fuit depuis hier soir. L''eau coule sous le carrelage.',
    'plomberie',
    'haute',
    'ouvert'
);
*/

-- ============================================================
-- SAMPLE VISIT
-- ============================================================
/*
INSERT INTO public.visites (
    propriete_id,
    agent_id,
    visiteur_nom,
    visiteur_email,
    visiteur_telephone,
    visiteur_type,
    date_visite,
    heure_debut,
    statut
) VALUES (
    'PROPRIETE_UUID',
    'AGENT_UUID',
    'Marie Claire',
    'marie@email.com',
    '+509 3900-0000',
    'locataire_potentiel',
    CURRENT_DATE + INTERVAL '3 days',
    '10:00',
    'planifiee'
);
*/

-- ============================================================
-- NOTIFICATION TEMPLATES
-- ============================================================
INSERT INTO public.parametres (cle, valeur, label, groupe) VALUES
    ('notif_template_paiement_recu', 
     'Votre paiement de {montant} {devise} pour {periode} a été reçu. Merci!',
     'Template notification paiement reçu', 'notifications'),
    ('notif_template_paiement_retard',
     'Rappel: Votre paiement de {montant} {devise} est en retard de {jours} jours.',
     'Template notification retard', 'notifications'),
    ('notif_template_contrat_expire',
     'Votre contrat de location expire dans {jours} jours. Contactez-nous pour le renouvellement.',
     'Template expiration contrat', 'notifications'),
    ('notif_template_ticket_resolu',
     'Bonne nouvelle! Votre ticket #{reference} a été résolu.',
     'Template ticket résolu', 'notifications')
ON CONFLICT (cle) DO NOTHING;

-- ============================================================
-- CATEGORY OPTIONS
-- ============================================================
INSERT INTO public.parametres (cle, valeur, label, groupe) VALUES
    ('ticket_categories', 
     '["maintenance","plomberie","electricite","paiement","bruit","securite","nettoyage","autre"]',
     'Catégories de tickets', 'systeme'),
    ('types_proprietaire',
     '["particulier","entreprise","syndic"]',
     'Types de propriétaires', 'systeme'),
    ('modes_paiement',
     '["virement","cheque","especes","mobile_money","paypal"]',
     'Modes de paiement acceptés', 'systeme'),
    ('frequences_rapport',
     '["hebdomadaire","mensuel","trimestriel","annuel"]',
     'Fréquences de rapport', 'systeme')
ON CONFLICT (cle) DO NOTHING;

-- ============================================================
-- BUSINESS RULES
-- ============================================================
INSERT INTO public.parametres (cle, valeur, label, groupe) VALUES
    ('commission_defaut', '10', 'Commission par défaut (%)', 'business'),
    ('depot_garantie_mois', '2', 'Mois de garantie requis', 'business'),
    ('penalite_retard_pct', '5', 'Pénalité de retard (%)', 'business'),
    ('jours_grace', '5', 'Jours de grâce pour paiement', 'business'),
    ('preavis_jours', '30', 'Préavis requis (jours)', 'business'),
    ('rappel_avant_echeance', '3', 'Rappel avant échéance (jours)', 'business'),
    ('score_paiement_initial', '100', 'Score paiement initial', 'business'),
    ('points_retard', '-10', 'Points perdus par retard', 'business')
ON CONFLICT (cle) DO NOTHING;
