-- ============================================================
-- Auto-créer profil
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name','Administrateur'),
    NEW.email
  );
  RETURN NEW;
EXCEPTION WHEN unique_violation THEN RETURN NEW;
END; $$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Auto-référence propriété
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS propriete_seq START 1;

CREATE OR REPLACE FUNCTION public.generer_reference()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.reference IS NULL OR NEW.reference = '' THEN
    NEW.reference := 'IH-' || TO_CHAR(NOW(),'YYYY') || '-' ||
                     LPAD(NEXTVAL('propriete_seq')::TEXT,4,'0');
  END IF;
  RETURN NEW;
END; $$;

CREATE TRIGGER set_reference
  BEFORE INSERT ON public.proprietes
  FOR EACH ROW EXECUTE FUNCTION public.generer_reference();

-- ============================================================
-- updated_at automatik
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

CREATE TRIGGER upd_profiles   BEFORE UPDATE ON public.profiles   FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_proprietes BEFORE UPDATE ON public.proprietes FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER upd_agents     BEFORE UPDATE ON public.agents     FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- Notifikasyon nouvo contact
-- ============================================================
CREATE OR REPLACE FUNCTION public.notifier_contact()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE prop_titre TEXT;
BEGIN
  SELECT titre INTO prop_titre
  FROM public.proprietes WHERE id = NEW.propriete_id;

  INSERT INTO public.notifications (type, titre, corps, reference_id, reference_table)
  VALUES (
    CASE NEW.type_demande
      WHEN 'visite'      THEN 'nouvelle_visite'
      WHEN 'offre'       THEN 'nouvelle_offre'
      ELSE 'nouveau_contact'
    END,
    CASE NEW.type_demande
      WHEN 'visite'     THEN 'Demande de visite — ' || NEW.nom
      WHEN 'offre'      THEN 'Offre reçue — ' || NEW.nom
      WHEN 'rendez_vous'THEN 'Rendez-vous — ' || NEW.nom
      ELSE 'Nouveau message — ' || NEW.nom
    END,
    COALESCE(prop_titre,'Contact général') || ' · ' || NEW.telephone,
    NEW.id, 'contacts'
  );
  RETURN NEW;
END; $$;

CREATE TRIGGER on_nouveau_contact
  AFTER INSERT ON public.contacts
  FOR EACH ROW EXECUTE FUNCTION public.notifier_contact();

-- ============================================================
-- Inkreman vues
-- ============================================================
CREATE OR REPLACE FUNCTION public.incrementer_vues(p_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.proprietes SET vue_count = vue_count + 1 WHERE id = p_id;
END; $$;

-- ============================================================
-- Rechèch avanse
-- ============================================================
CREATE OR REPLACE FUNCTION public.rechercher_proprietes(
  p_transaction    TEXT    DEFAULT NULL,
  p_type           TEXT    DEFAULT NULL,
  p_zone_id        UUID    DEFAULT NULL,
  p_prix_min       NUMERIC DEFAULT NULL,
  p_prix_max       NUMERIC DEFAULT NULL,
  p_chambres_min   INTEGER DEFAULT NULL,
  p_superficie_min NUMERIC DEFAULT NULL,
  p_mot_cle        TEXT    DEFAULT NULL,
  p_meuble         BOOLEAN DEFAULT NULL,
  p_limit          INTEGER DEFAULT 12,
  p_offset         INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID, reference TEXT, titre TEXT, slug TEXT,
  type_transaction TEXT, type_propriete TEXT,
  prix NUMERIC, devise TEXT, prix_loyer NUMERIC,
  superficie_m2 NUMERIC, nb_chambres INTEGER,
  nb_salles_bain INTEGER, nb_garages INTEGER,
  images TEXT[], statut TEXT,
  est_vedette BOOLEAN, est_nouveau BOOLEAN, vue_count INTEGER,
  zone_nom TEXT, ville TEXT,
  agent_nom TEXT, agent_photo TEXT, agent_tel TEXT,
  created_at TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.reference, p.titre, p.slug,
    p.type_transaction, p.type_propriete,
    p.prix, p.devise, p.prix_loyer,
    p.superficie_m2, p.nb_chambres,
    p.nb_salles_bain, p.nb_garages,
    p.images, p.statut,
    p.est_vedette, p.est_nouveau, p.vue_count,
    z.nom  AS zone_nom, p.ville,
    (a.prenom||' '||a.nom) AS agent_nom,
    a.photo_url AS agent_photo,
    a.telephone AS agent_tel,
    p.created_at,
    COUNT(*) OVER() AS total_count
  FROM public.proprietes p
  LEFT JOIN public.zones  z ON z.id = p.zone_id
  LEFT JOIN public.agents a ON a.id = p.agent_id
  WHERE p.est_actif = TRUE
    AND p.statut    = 'disponible'
    AND (p_transaction    IS NULL OR p.type_transaction = p_transaction)
    AND (p_type           IS NULL OR p.type_propriete   = p_type)
    AND (p_zone_id        IS NULL OR p.zone_id          = p_zone_id)
    AND (p_prix_min       IS NULL OR p.prix             >= p_prix_min)
    AND (p_prix_max       IS NULL OR p.prix             <= p_prix_max)
    AND (p_chambres_min   IS NULL OR p.nb_chambres      >= p_chambres_min)
    AND (p_superficie_min IS NULL OR p.superficie_m2    >= p_superficie_min)
    AND (p_meuble         IS NULL OR p.meuble           = p_meuble)
    AND (p_mot_cle IS NULL OR (
          unaccent(lower(p.titre))       ILIKE '%'||unaccent(lower(p_mot_cle))||'%'
       OR unaccent(lower(p.description)) ILIKE '%'||unaccent(lower(p_mot_cle))||'%'
       OR unaccent(lower(p.adresse))     ILIKE '%'||unaccent(lower(p_mot_cle))||'%'
    ))
  ORDER BY p.est_vedette DESC, p.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END; $$;

-- ============================================================
-- Dashboard stats
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
  SELECT json_build_object(
    'total_proprietes',
      (SELECT COUNT(*) FROM public.proprietes WHERE est_actif=TRUE),
    'disponibles',
      (SELECT COUNT(*) FROM public.proprietes WHERE statut='disponible' AND est_actif=TRUE),
    'vendues',
      (SELECT COUNT(*) FROM public.proprietes WHERE statut='vendu'),
    'louees',
      (SELECT COUNT(*) FROM public.proprietes WHERE statut='loue'),
    'contacts_nouveaux',
      (SELECT COUNT(*) FROM public.contacts WHERE statut='nouveau'),
    'contacts_ce_mois',
      (SELECT COUNT(*) FROM public.contacts
        WHERE DATE_TRUNC('month',created_at)=DATE_TRUNC('month',CURRENT_DATE)),
    'total_agents',
      (SELECT COUNT(*) FROM public.agents WHERE actif=TRUE),
    'vues_totales',
      (SELECT COALESCE(SUM(vue_count),0) FROM public.proprietes),
    'visites_ce_mois',
      (SELECT COUNT(*) FROM public.contacts
        WHERE type_demande='visite'
          AND DATE_TRUNC('month',created_at)=DATE_TRUNC('month',CURRENT_DATE)),
    'par_type',
      (SELECT json_agg(row_to_json(t)) FROM (
        SELECT type_propriete, COUNT(*) total
        FROM public.proprietes WHERE est_actif=TRUE
        GROUP BY type_propriete ORDER BY total DESC
      ) t),
    'top_zones',
      (SELECT json_agg(row_to_json(t)) FROM (
        SELECT z.nom, COUNT(p.id) total
        FROM public.proprietes p
        JOIN public.zones z ON z.id=p.zone_id
        WHERE p.est_actif=TRUE
        GROUP BY z.nom ORDER BY total DESC LIMIT 5
      ) t),
    'contacts_par_mois',
      (SELECT json_agg(row_to_json(t)) FROM (
        SELECT TO_CHAR(DATE_TRUNC('month',created_at),'Mon YYYY') mois,
               COUNT(*) total
        FROM public.contacts
        WHERE created_at >= NOW() - INTERVAL '6 months'
        GROUP BY DATE_TRUNC('month',created_at)
        ORDER BY DATE_TRUNC('month',created_at)
      ) t)
  ) INTO result;
  RETURN result;
END; $$;
