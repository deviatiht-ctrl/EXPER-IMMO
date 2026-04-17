import CONFIG from './config.js';

const { createClient } = supabase;

export const supabaseClient = createClient(
  CONFIG.SUPABASE_URL,
  CONFIG.SUPABASE_ANON_KEY
);

// Alias — plusieurs fichiers admin importent { supabase } par erreur
export { supabaseClient as supabase };
