-- ============================================================
-- EXPER IMMO - STORAGE & ADMIN SETUP
-- Supabase Storage Buckets and Admin Functions
-- ============================================================

-- ============================================================
-- 1. STORAGE BUCKETS
-- ============================================================

-- Create property-images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'property-images',
    'property-images',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Create profile-avatars bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-avatars',
    'profile-avatars',
    true,
    2097152, -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 2097152,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Create documents bucket (for contracts, ID cards, etc.)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'documents',
    'documents',
    false, -- Private
    10485760, -- 10MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/png'];

-- ============================================================
-- 2. STORAGE POLICIES
-- ============================================================

-- Property Images Policies
CREATE POLICY "Public can view property images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'property-images');

CREATE POLICY "Admin can upload property images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'property-images'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admin can delete property images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'property-images'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Profile Avatars Policies
CREATE POLICY "Public can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'profile-avatars');

CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can update own avatar"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'profile-avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Admin can manage all avatars"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'profile-avatars'
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Documents Policies (Private)
CREATE POLICY "Users can view own documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'documents'
        AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = auth.uid() AND role = 'admin'
            )
        )
    );

CREATE POLICY "Users can upload own documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- ============================================================
-- 3. ADMIN HELPER FUNCTIONS
-- ============================================================

-- Function to get admin dashboard stats
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_proprietaires', (SELECT COUNT(*) FROM public.proprietaires),
        'total_locataires', (SELECT COUNT(*) FROM public.locataires),
        'total_proprietes', (SELECT COUNT(*) FROM public.proprietes),
        'proprietes_disponibles', (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'disponible'),
        'proprietes_louees', (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'loue'),
        'total_contrats_actifs', (SELECT COUNT(*) FROM public.contrats_location WHERE statut = 'actif'),
        'paiements_en_attente', (SELECT COUNT(*) FROM public.paiements WHERE statut = 'en_attente'),
        'tickets_ouverts', (SELECT COUNT(*) FROM public.tickets_support WHERE statut = 'ouvert'),
        'revenus_mensuels', (SELECT COALESCE(SUM(montant_total), 0) FROM public.paiements 
                              WHERE statut = 'paye' 
                              AND date_paiement >= date_trunc('month', NOW()))
    ) INTO result;
    
    RETURN result;
END;
$$;

-- Function to get proprietaire details with properties
CREATE OR REPLACE FUNCTION public.get_proprietaire_details(p_proprietaire_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'id', p.id,
        'type_proprietaire', p.type_proprietaire,
        'nom_entreprise', p.nom_entreprise,
        'numero_fiscal', p.numero_fiscal,
        'nombre_proprietes', p.nb_proprietes,
        'revenu_mensuel', p.revenu_total,
        'created_at', p.created_at,
        'user', json_build_object(
            'full_name', pr.full_name,
            'email', pr.email,
            'phone', pr.phone,
            'avatar_url', pr.avatar_url,
            'is_active', pr.is_active,
            'is_verified', pr.is_verified,
            'adresse', pr.adresse,
            'ville', pr.ville
        ),
        'proprietes', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', prop.id,
                'titre', prop.titre,
                'prix_location', prop.prix_location,
                'statut', prop.statut,
                'adresse', prop.adresse,
                'ville', prop.ville,
                'type_bien', prop.type_bien
            ))
            FROM public.proprietes prop
            WHERE prop.proprietaire_id = p.id),
            '[]'::json
        )
    )
    INTO result
    FROM public.proprietaires p
    JOIN public.profiles pr ON pr.id = p.user_id
    WHERE p.id = p_proprietaire_id;
    
    RETURN result;
END;
$$;

-- Function to create proprietaire with user
CREATE OR REPLACE FUNCTION public.create_proprietaire(
    p_email TEXT,
    p_full_name TEXT,
    p_phone TEXT,
    p_adresse TEXT DEFAULT NULL,
    p_ville TEXT DEFAULT NULL,
    p_type_proprietaire TEXT DEFAULT 'particulier',
    p_nom_entreprise TEXT DEFAULT NULL,
    p_numero_fiscal TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    new_proprietaire_id UUID;
    temp_password TEXT;
BEGIN
    -- Generate temporary password
    temp_password := substr(md5(random()::text), 1, 12);
    
    -- Create auth user (this would normally be done via supabase.auth.admin.createUser)
    -- For now, return the data needed to create user via client
    
    RETURN json_build_object(
        'success', true,
        'message', 'Utilisez la fonction auth.admin.createUser via l''API Supabase',
        'temp_password', temp_password,
        'user_data', json_build_object(
            'email', p_email,
            'password', temp_password,
            'user_metadata', json_build_object(
                'full_name', p_full_name,
                'role', 'proprietaire'
            )
        )
    );
END;
$$;

-- Function to update proprietaire stats (trigger)
CREATE OR REPLACE FUNCTION public.update_proprietaire_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update proprietaire property count and revenue
    UPDATE public.proprietaires
    SET 
        nb_proprietes = (
            SELECT COUNT(*) 
            FROM public.proprietes 
            WHERE proprietaire_id = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id)
        ),
        revenu_total = (
            SELECT COALESCE(SUM(prix_location), 0)
            FROM public.proprietes
            WHERE proprietaire_id = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id)
            AND statut = 'loue'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.proprietaire_id, OLD.proprietaire_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create trigger for proprietaire stats
DROP TRIGGER IF EXISTS update_proprietaire_stats_trigger ON public.proprietes;
CREATE TRIGGER update_proprietaire_stats_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.proprietes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_proprietaire_stats();

-- ============================================================
-- 4. ADMIN VIEWS
-- ============================================================

-- View for admin proprietaires list
CREATE OR REPLACE VIEW public.admin_proprietaires_view AS
SELECT 
    p.id,
    p.type_proprietaire,
    p.nom_entreprise,
    p.numero_fiscal,
    p.nb_proprietes as nombre_proprietes,
    p.revenu_total as revenu_mensuel,
    p.created_at,
    pr.full_name,
    pr.email,
    pr.phone,
    pr.avatar_url,
    pr.is_active,
    pr.is_verified,
    pr.adresse,
    pr.ville
FROM public.proprietaires p
JOIN public.profiles pr ON pr.id = p.user_id;

-- View for admin dashboard
CREATE OR REPLACE VIEW public.admin_dashboard_view AS
SELECT
    (SELECT COUNT(*) FROM public.proprietaires) as total_proprietaires,
    (SELECT COUNT(*) FROM public.locataires) as total_locataires,
    (SELECT COUNT(*) FROM public.proprietes) as total_proprietes,
    (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'disponible') as proprietes_disponibles,
    (SELECT COUNT(*) FROM public.proprietes WHERE statut = 'loue') as proprietes_louees,
    (SELECT COUNT(*) FROM public.contrats_location WHERE statut = 'actif') as contrats_actifs,
    (SELECT COALESCE(SUM(montant_total), 0) FROM public.paiements 
     WHERE statut = 'paye' AND date_paiement >= date_trunc('month', NOW())) as revenus_mensuels;

-- ============================================================
-- 5. RLS POLICIES FOR ADMIN VIEWS
-- ============================================================

CREATE POLICY "Admin can view proprietaires view"
    ON public.proprietaires FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    ));

-- ============================================================
-- 6. ENABLE REALTIME FOR ADMIN
-- ============================================================

-- Enable realtime for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.proprietaires;
ALTER PUBLICATION supabase_realtime ADD TABLE public.locataires;
ALTER PUBLICATION supabase_realtime ADD TABLE public.proprietes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.paiements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets_support;

-- ============================================================
-- NOTES FOR SETUP
-- ============================================================

/*
IMPORTANT: To complete storage setup, you must also:

1. In Supabase Dashboard:
   - Go to Storage → Policies
   - Enable RLS on all buckets
   - Verify policies are active

2. For image uploads to work:
   - Install the Supabase Storage JS client
   - Use the upload function with proper path structure:
     - property-images: 'property-id/image-name.jpg'
     - profile-avatars: 'user-id/avatar.jpg'
     - documents: 'user-id/document-name.pdf'

3. CORS Configuration (if needed):
   - Allow your domain in Storage settings
   - Allow methods: GET, POST, PUT, DELETE
   - Allow headers: authorization, x-client-info, apikey, content-type

4. To create first admin user:
   INSERT INTO public.profiles (id, email, full_name, role, is_verified)
   VALUES ('user-uuid-from-auth', 'admin@example.com', 'Admin', 'admin', true);
*/
