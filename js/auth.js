// auth.js - Authentication Handler for EXPER IMMO
import CONFIG from './config.js';
import { showToast } from './utils.js';

const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

// ============================================================
// UTILITY FUNCTIONS
// ============================================================
const getElement = (id) => document.getElementById(id);

const showStep = (stepId) => {
    document.querySelectorAll('.auth-step, .reg-step').forEach(step => step.classList.remove('active'));
    const step = getElement(stepId);
    if (step) step.classList.add('active');
};

const setLoading = (button, loading) => {
    if (loading) {
        button.disabled = true;
        button.innerHTML = '<i data-lucide="loader-2" class="spin"></i> Chargement...';
    } else {
        button.disabled = false;
    }
    lucide.createIcons();
};

// ============================================================
// STEP INDICATOR HELPER
// ============================================================
const updateStepIndicator = (currentStep) => {
    const dots = [
        document.getElementById('dot-1'),
        document.getElementById('dot-2'),
        document.getElementById('dot-3')
    ];
    const lines = [
        document.getElementById('line-1'),
        document.getElementById('line-2')
    ];
    if (!dots[0]) return;
    dots.forEach((dot, i) => {
        if (!dot) return;
        dot.classList.remove('active', 'done');
        if (i + 1 < currentStep) dot.classList.add('done');
        else if (i + 1 === currentStep) dot.classList.add('active');
    });
    lines.forEach((line, i) => {
        if (!line) return;
        line.classList.toggle('done', i + 1 < currentStep);
    });
};

// ============================================================
// REGISTRATION PAGE
// ============================================================
const initRegistrationPage = () => {
    const roleCards = document.querySelectorAll('.auth-role-card, .role-card');
    const registerForm = getElement('register-form');
    const btnBackRole = getElement('btn-back-role');
    const typeProprietaire = getElement('type_proprietaire');
    
    let selectedRole = null;

    updateStepIndicator(1);

    // Role selection — supports both old (.auth-role-card) and new (.reg-role-card) class names
    const allRoleCards = document.querySelectorAll('.auth-role-card, .role-card, .reg-role-card');
    allRoleCards.forEach(card => {
        card.addEventListener('click', () => {
            selectedRole = card.dataset.role;
            const roleInput = getElement('selected-role');
            if (roleInput) roleInput.value = selectedRole;

            const propFields = getElement('proprietaire-fields');
            const locFields  = getElement('locataire-fields');
            if (selectedRole === 'proprietaire') {
                if (propFields) propFields.style.display = 'block';
                if (locFields)  locFields.style.display  = 'none';
            } else {
                if (propFields) propFields.style.display = 'none';
                if (locFields)  locFields.style.display  = 'block';
            }

            showStep('step-info');
            updateStepIndicator(2);
            lucide.createIcons();
        });
    });

    // Back button
    if (btnBackRole) {
        btnBackRole.addEventListener('click', () => {
            showStep('step-role');
            updateStepIndicator(1);
        });
    }

    // Type proprietaire change
    if (typeProprietaire) {
        typeProprietaire.addEventListener('change', (e) => {
            const entrepriseField = getElement('entreprise-field');
            if (e.target.value === 'entreprise' || e.target.value === 'syndic') {
                entrepriseField.style.display = 'block';
            } else {
                entrepriseField.style.display = 'none';
            }
        });
    }

    // Password toggle
    document.querySelectorAll('.btn-toggle-password').forEach(btn => {
        btn.addEventListener('click', () => {
            const input = btn.previousElementSibling;
            const icon = btn.querySelector('i');
            if (input.type === 'password') {
                input.type = 'text';
                icon.setAttribute('data-lucide', 'eye-off');
            } else {
                input.type = 'password';
                icon.setAttribute('data-lucide', 'eye');
            }
            lucide.createIcons();
        });
    });

    // Form submission
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const password        = getElement('password')?.value        || '';
            const passwordConfirm = getElement('password_confirm')?.value || '';

            if (password !== passwordConfirm) {
                showToast('Les mots de passe ne correspondent pas', 'error');
                return;
            }
            if (password.length < 8) {
                showToast('Le mot de passe doit contenir au moins 8 caractères', 'error');
                return;
            }

            // Validate ID photos
            const rectoFile = getElement('id_recto')?.files[0];
            const versoFile = getElement('id_verso')?.files[0];
            if (!rectoFile || !versoFile) {
                showToast('Veuillez joindre les deux photos de votre pièce d\'identité', 'error');
                return;
            }

            const btnRegister = getElement('btn-register');
            setLoading(btnRegister, true);

            try {
                // Collect all fields
                const email          = getElement('email')?.value        || '';
                const full_name      = getElement('full_name')?.value    || '';
                const phone          = getElement('phone')?.value        || '';
                const role           = getElement('selected-role')?.value || '';
                const adresse        = getElement('adresse')?.value      || '';
                const date_naissance = getElement('date_naissance')?.value || '';
                const nationalite    = getElement('nationalite')?.value  || '';
                const piece_type     = getElement('piece_type')?.value   || '';
                const piece_numero   = getElement('piece_numero')?.value || '';
                // Role-specific extras
                const profession     = getElement('profession')?.value   || '';
                const employeur      = getElement('employeur')?.value    || '';
                const type_prop      = getElement('type_proprietaire')?.value || '';
                const nom_entreprise = getElement('nom_entreprise')?.value || '';

                // 1 — Create auth account
                const { data, error } = await supabaseClient.auth.signUp({
                    email,
                    password,
                    options: {
                        data: { full_name, phone, role }
                    }
                });
                if (error) throw error;

                const userId = data.user?.id;

                // 2 — Upload ID photos to Storage (best-effort, may fail if email confirmation pending)
                let rectoUrl = null;
                let versoUrl = null;
                if (userId) {
                    try {
                        const uploadFile = async (file, side) => {
                            const ext  = file.name.split('.').pop().toLowerCase();
                            const path = `${userId}/${side}.${ext}`;
                            const { error: upErr } = await supabaseClient.storage
                                .from('documents-identite')
                                .upload(path, file, { upsert: true, contentType: file.type });
                            if (upErr) { console.warn('[Upload]', side, upErr.message); return null; }
                            return supabaseClient.storage.from('documents-identite').getPublicUrl(path).data.publicUrl;
                        };
                        rectoUrl = await uploadFile(rectoFile, 'recto');
                        versoUrl = await uploadFile(versoFile, 'verso');
                    } catch (upErr) {
                        console.warn('[Storage] Upload partiel:', upErr.message);
                    }

                    // 3 — Upsert profile record with all collected data
                    try {
                        await supabaseClient.from('profiles').upsert({
                            id: userId,
                            full_name,
                            phone,
                            role,
                            adresse,
                            date_naissance: date_naissance || null,
                            nationalite,
                            piece_identite_type:      piece_type,
                            piece_identite_numero:    piece_numero,
                            piece_identite_recto_url: rectoUrl,
                            piece_identite_verso_url: versoUrl,
                            profession,
                            employeur,
                            type_proprietaire: type_prop,
                            nom_entreprise,
                            statut_dossier: 'en_attente'
                        }, { onConflict: 'id' });
                    } catch (profErr) {
                        console.warn('[Profile] Upsert partiel:', profErr.message);
                    }
                }

                // 4 — Show verification step
                const confirmEl = getElement('confirm-email');
                if (confirmEl) confirmEl.textContent = email;
                showStep('step-verify');
                updateStepIndicator(3);

            } catch (error) {
                console.error('Registration error:', error);
                showToast(error.message || 'Erreur lors de l\'inscription', 'error');
                btnRegister.innerHTML = '<i data-lucide="user-plus"></i> Créer mon compte';
                btnRegister.disabled = false;
                lucide.createIcons();
            }
        });
    }

    // Resend verification email
    const btnResend = getElement('btn-resend');
    if (btnResend) {
        btnResend.addEventListener('click', async () => {
            const email = getElement('email').value;
            try {
                const { error } = await supabaseClient.auth.resend({
                    type: 'signup',
                    email: email
                });
                if (error) throw error;
                showToast('Email de vérification renvoyé!', 'success');
            } catch (error) {
                showToast(error.message, 'error');
            }
        });
    }
};

// ============================================================
// LOGIN PAGE
// ============================================================
const initLoginPage = () => {
    const loginForm = getElement('login-form');
    
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const email = getElement('email').value;
            const password = getElement('password').value;
            const btnLogin = loginForm.querySelector('button[type="submit"]');
            
            setLoading(btnLogin, true);

            try {
                const { data, error } = await supabaseClient.auth.signInWithPassword({
                    email: email,
                    password: password
                });

                if (error) throw error;

                // Get user profile to determine redirect
                const { data: profile, error: profileError } = await supabaseClient
                    .from('profiles')
                    .select('role')
                    .eq('id', data.user.id)
                    .single();

                if (profileError) throw profileError;

                showToast('Connexion réussie!', 'success');

                // Mettre à jour dernière connexion (Optionnel, sans bloquer le login)
                try {
                    await supabaseClient.rpc('update_derniere_connexion', { p_user_id: data.user.id });
                } catch (e) {
                    console.warn("Erreur mise à jour date connexion:", e);
                }

                // Redirect based on role
                setTimeout(() => {
                    const role = (profile.role || 'locataire').toLowerCase().trim();
                    console.log("Rôle détecté:", role);
                    
                    switch (role) {
                        case 'admin':
                        case 'assistante':
                            window.location.href = 'admin/dashboard.html';
                            break;
                        case 'gestionnaire':
                            window.location.href = 'gestionnaire/index.html';
                            break;
                        case 'proprietaire':
                            window.location.href = 'proprietaire/index.html';
                            break;
                        case 'locataire':
                        default:
                            window.location.href = 'locataire/index.html';
                    }
                }, 1000);

            } catch (error) {
                console.error('Login error:', error);
                showToast(error.message || 'Email ou mot de passe incorrect', 'error');
                btnLogin.innerHTML = '<i data-lucide="log-in"></i> Se connecter';
                btnLogin.disabled = false;
                lucide.createIcons();
            }
        });
    }

    // Password toggle
    document.querySelectorAll('.btn-toggle-password').forEach(btn => {
        btn.addEventListener('click', () => {
            const input = btn.previousElementSibling;
            const icon = btn.querySelector('i');
            if (input.type === 'password') {
                input.type = 'text';
                icon.setAttribute('data-lucide', 'eye-off');
            } else {
                input.type = 'password';
                icon.setAttribute('data-lucide', 'eye');
            }
            lucide.createIcons();
        });
    });
};

// ============================================================
// FORGOT PASSWORD PAGE
// ============================================================
const initForgotPasswordPage = () => {
    const form = getElement('forgot-password-form');
    
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const email = getElement('email').value;
            const btn = form.querySelector('button[type="submit"]');
            
            setLoading(btn, true);

            try {
                const { error } = await supabaseClient.auth.resetPasswordForEmail(email, {
                    redirectTo: `${window.location.origin}/reset-password.html`
                });

                if (error) throw error;

                showToast('Email de réinitialisation envoyé!', 'success');
                showStep('step-sent');
                
            } catch (error) {
                showToast(error.message, 'error');
                btn.disabled = false;
            }
        });
    }
};

// ============================================================
// AUTH STATE CHECK
// ============================================================
export const checkAuth = async () => {
    const { data: { session } } = await supabaseClient.auth.getSession();
    return session;
};

export const getCurrentUser = async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) return null;
    
    const { data: profile } = await supabaseClient
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();
    
    return { ...user, profile };
};

export const requireAuth = async (allowedRoles = []) => {
    const user = await getCurrentUser();
    
    if (!user) {
        window.location.href = '/login.html';
        return null;
    }
    
    if (allowedRoles.length > 0 && !allowedRoles.includes(user.profile?.role)) {
        showToast('Accès non autorisé', 'error');
        window.location.href = '/index.html';
        return null;
    }
    
    return user;
};

export const logout = async () => {
    await supabaseClient.auth.signOut();
    window.location.href = '/index.html';
};

// ============================================================
// INITIALIZE
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
    // Detect which page we're on
    const path = window.location.pathname;
    
    if (path.includes('inscription')) {
        initRegistrationPage();
    } else if (path.includes('login') || path.includes('connexion')) {
        initLoginPage();
    } else if (path.includes('forgot-password')) {
        initForgotPasswordPage();
    }
});

// Export for use in other modules
export { supabaseClient };
