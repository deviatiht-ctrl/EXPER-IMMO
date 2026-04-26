import apiClient from './api-client.js';
import { showToast } from './utils.js';

// Déterminer le préfixe du chemin (pour les redirections)
const folders = ['admin', 'gestionnaire', 'locataire', 'proprietaire', 'properties'];
const needsPrefix = folders.some(f => window.location.pathname.includes('/' + f + '/'));
const prefix = needsPrefix ? '../' : '';

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
    const dots  = ['dot-1','dot-2','dot-3','dot-4'].map(id => document.getElementById(id));
    const lines = ['line-1','line-2','line-3'].map(id => document.getElementById(id));
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
            showStep('step-code');
            updateStepIndicator(2);
            lucide.createIcons();
        });
    });

    // Back from code step → role
    const btnBackCode = getElement('btn-back-code');
    if (btnBackCode) {
        btnBackCode.addEventListener('click', () => {
            showStep('step-role');
            updateStepIndicator(1);
        });
    }

    // Back from info step → code
    if (btnBackRole) {
        btnBackRole.addEventListener('click', () => {
            showStep('step-code');
            updateStepIndicator(2);
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

    // Code validation step
    const btnValidateCode = getElement('btn-validate-code');
    if (btnValidateCode) {
        btnValidateCode.addEventListener('click', async () => {
            const codeVal = (getElement('registration-code')?.value || '').trim().toUpperCase();
            if (!codeVal) { showToast('Veuillez saisir un code', 'error'); return; }
            setLoading(btnValidateCode, true);
            try {
                const result = await apiClient.post('/auth/validate-code', { code: codeVal });
                // Store validated code & role
                const roleInput = getElement('selected-role');
                if (roleInput) roleInput.value = result.role;
                selectedRole = result.role;

                // Pre-fill email if provided
                const emailInput = getElement('email');
                if (emailInput && result.email_beneficiaire) emailInput.value = result.email_beneficiaire;

                // Show/hide role fields
                const propFields = getElement('proprietaire-fields');
                const locFields  = getElement('locataire-fields');
                if (result.role === 'proprietaire') {
                    if (propFields) propFields.style.display = 'block';
                    if (locFields)  locFields.style.display  = 'none';
                } else {
                    if (propFields) propFields.style.display = 'none';
                    if (locFields)  locFields.style.display  = 'block';
                }

                showToast(`Code valide — Bienvenue, ${result.nom_beneficiaire || ''}!`, 'success');
                showStep('step-info');
                updateStepIndicator(2);
                lucide.createIcons();
            } catch (err) {
                showToast(err.message || 'Code invalide', 'error');
                btnValidateCode.innerHTML = '<i data-lucide="arrow-right"></i> Valider le code';
                btnValidateCode.disabled = false;
                lucide.createIcons();
            }
        });
    }

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

            const btnRegister = getElement('btn-register');
            setLoading(btnRegister, true);

            try {
                const code           = (getElement('registration-code')?.value || '').trim().toUpperCase();
                const email          = getElement('email')?.value        || '';
                const full_name      = getElement('full_name')?.value    || '';
                const phone          = getElement('phone')?.value        || '';
                const adresse        = getElement('adresse')?.value      || '';
                const date_naissance = getElement('date_naissance')?.value || '';
                const nationalite    = getElement('nationalite')?.value  || '';
                const piece_type     = getElement('piece_type')?.value   || '';
                const piece_numero   = getElement('piece_numero')?.value || '';
                const profession     = getElement('profession')?.value   || '';
                const employeur      = getElement('employeur')?.value    || '';
                const type_prop      = getElement('type_proprietaire')?.value || 'particulier';
                const nom_entreprise = getElement('nom_entreprise')?.value || '';

                const data = await apiClient.post('/auth/register-with-code', {
                    code, email, password, full_name, phone,
                    adresse, date_naissance, nationalite,
                    piece_type, piece_numero,
                    profession, employeur,
                    type_proprietaire: type_prop,
                    nom_entreprise,
                });

                if (data.access_token) {
                    localStorage.setItem('exper_immo_token', data.access_token);
                    localStorage.setItem('exper_immo_user', JSON.stringify(data.user));
                }

                showToast('Compte créé avec succès !', 'success');
                showStep('step-verify');
                updateStepIndicator(3);
                const confirmEl = getElement('confirm-email');
                if (confirmEl) confirmEl.textContent = email;

                setTimeout(() => {
                    const role = data.user?.role || 'locataire';
                    if (role === 'proprietaire') window.location.href = prefix + 'proprietaire/index.html';
                    else window.location.href = prefix + 'locataire/index.html';
                }, 2500);

            } catch (error) {
                console.error('Registration error:', error);
                showToast(error.message || 'Erreur lors de l\'inscription', 'error');
                btnRegister.innerHTML = '<i data-lucide="user-plus"></i> Créer mon compte';
                btnRegister.disabled = false;
                lucide.createIcons();
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
                const data = await apiClient.post('/auth/login', {
                    email: email,
                    password: password
                });

                // Store token and user
                localStorage.setItem('exper_immo_token', data.access_token);
                localStorage.setItem('exper_immo_user', JSON.stringify(data.user));

                showToast('Connexion réussie!', 'success');

                // Redirect based on role
                setTimeout(() => {
                    const role = (data.user.role || 'locataire').toLowerCase().trim();
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
            const email = getElement('email')?.value || '';
            const btn = form.querySelector('button[type="submit"]');
            setLoading(btn, true);
            showToast('Si cet email existe, un lien sera envoyé.', 'success');
            showStep('step-sent');
        });
    }
};

// ============================================================
// AUTH STATE CHECK
// ============================================================
export const checkAuth = async () => {
    return localStorage.getItem('exper_immo_token');
};

export const getCurrentUser = async () => {
    const userStr = localStorage.getItem('exper_immo_user');
    if (!userStr) return null;
    return JSON.parse(userStr);
};

export const requireAuth = async (allowedRoles = []) => {
    const user = await getCurrentUser();
    
    if (!user) {
        window.location.href = prefix + 'login.html';
        return null;
    }
    
    if (allowedRoles.length > 0 && !allowedRoles.includes(user.role)) {
        showToast('Accès non autorisé', 'error');
        window.location.href = prefix + 'index.html';
        return null;
    }
    
    return user;
};

export const logout = async () => {
    localStorage.removeItem('exper_immo_token');
    localStorage.removeItem('exper_immo_user');
    window.location.href = prefix + 'index.html';
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

// showToast is used globally — expose it
if (typeof window !== 'undefined') {
    window.showToast = showToast;
}
