ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zones         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proprietes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parametres    ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = TRUE
  );
$$;

-- PROFILES
CREATE POLICY "p_sel" ON public.profiles FOR SELECT USING (auth.uid()=id OR public.is_admin());
CREATE POLICY "p_ins" ON public.profiles FOR INSERT WITH CHECK (auth.uid()=id);
CREATE POLICY "p_upd" ON public.profiles FOR UPDATE USING (auth.uid()=id OR public.is_admin());

-- AGENTS (piblik an lekti)
CREATE POLICY "ag_sel" ON public.agents FOR SELECT USING (TRUE);
CREATE POLICY "ag_adm" ON public.agents FOR ALL   USING (public.is_admin());

-- ZONES (piblik an lekti)
CREATE POLICY "zo_sel" ON public.zones FOR SELECT USING (TRUE);
CREATE POLICY "zo_adm" ON public.zones FOR ALL   USING (public.is_admin());

-- PROPRIETES
CREATE POLICY "prop_pub" ON public.proprietes
  FOR SELECT USING (est_actif=TRUE OR public.is_admin());
CREATE POLICY "prop_adm" ON public.proprietes
  FOR ALL USING (public.is_admin());

-- CONTACTS
CREATE POLICY "cont_ins" ON public.contacts FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "cont_sel" ON public.contacts FOR SELECT USING (public.is_admin());
CREATE POLICY "cont_upd" ON public.contacts FOR UPDATE USING (public.is_admin());

-- NOTIFICATIONS
CREATE POLICY "notif_adm" ON public.notifications FOR ALL USING (public.is_admin());

-- PARAMETRES
CREATE POLICY "par_sel" ON public.parametres FOR SELECT USING (TRUE);
CREATE POLICY "par_adm" ON public.parametres FOR ALL   USING (public.is_admin());
