from fastapi import FastAPI, Depends, HTTPException, Security, UploadFile, File
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import Optional, List
from pydantic import BaseModel, EmailStr
from jose import JWTError, jwt
import uvicorn
import os
import uuid
import shutil
from pathlib import Path
from datetime import date
from sqlalchemy import text

from . import models, database, auth

# Create tables
models.Base.metadata.create_all(bind=database.engine)

# Auto-create admin on startup (Render free tier - no shell access)
def create_admin_on_startup():
    db = database.SessionLocal()
    try:
        admin_email = os.getenv("ADMIN_EMAIL")
        admin_password = os.getenv("ADMIN_PASSWORD")
        admin_name = os.getenv("ADMIN_NAME", "Administrateur EXPERIMMO")
        
        if not admin_email or not admin_password:
            return
        
        existing = db.query(models.User).filter(models.User.email == admin_email).first()
        if existing:
            return
        
        user = models.User(
            email=admin_email,
            hashed_password=auth.get_password_hash(admin_password),
            full_name=admin_name,
            role="admin",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        db.add(models.Profile(id=user.id, full_name=admin_name, role="admin"))
        db.commit()
        print(f"[OK] Admin auto-created: {admin_email}")
    except Exception as e:
        print(f"[WARN] Could not auto-create admin: {e}")
    finally:
        db.close()

create_admin_on_startup()

# Create upload directory
UPLOAD_DIR = Path("static/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="EXPER IMMO API", version="2.0.0")

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────
# AUTH DEPENDENCY
# ─────────────────────────────────────────────
security_scheme = HTTPBearer()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security_scheme),
    db: Session = Depends(database.get_db)
):
    try:
        payload = jwt.decode(credentials.credentials, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        email: str = payload.get("sub")
        if not email:
            raise HTTPException(status_code=401, detail="Token invalide")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token invalide ou expiré")

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Utilisateur non trouvé ou désactivé")
    return user

def require_admin(current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ("admin",):
        raise HTTPException(status_code=403, detail="Accès réservé aux administrateurs")
    return current_user

# ─────────────────────────────────────────────
# SCHEMAS
# ─────────────────────────────────────────────
class UserLogin(BaseModel):
    email: str
    password: str

class UserCreate(BaseModel):
    email: str
    password: str
    full_name: str
    role: str = "locataire"
    phone: Optional[str] = None

class RegisterWithCode(BaseModel):
    code: str
    email: str
    password: str
    full_name: str
    phone: Optional[str] = None
    adresse: Optional[str] = None
    date_naissance: Optional[str] = None
    nationalite: Optional[str] = None
    piece_type: Optional[str] = None
    piece_numero: Optional[str] = None
    profession: Optional[str] = None
    employeur: Optional[str] = None
    type_proprietaire: Optional[str] = "particulier"
    nom_entreprise: Optional[str] = None

class GestionnaireCreate(BaseModel):
    nom: str
    prenom: str
    email: str
    password: str
    role: str = "gestionnaire"
    phone: Optional[str] = None

class ContratCreate(BaseModel):
    nom_proprietaire: str
    email_proprietaire: str
    nom_locataire: str
    email_locataire: str
    propriete_id: Optional[str] = None
    loyer_mensuel: float
    devise: str = "HTG"
    caution: float = 0
    date_debut: str
    date_fin: str
    notes: Optional[str] = None

class ProprieteCreate(BaseModel):
    titre: str
    reference: Optional[str] = None
    slug: Optional[str] = None
    type_bien: Optional[str] = None
    type_transaction: Optional[str] = None
    prix: float = 0
    devise: str = "USD"
    adresse: Optional[str] = None
    ville: str = "Pétion-Ville"
    nb_chambres: int = 0
    nb_salles_bain: int = 0
    superficie_m2: float = 0
    description: Optional[str] = None
    statut_bien: str = "disponible"
    images: Optional[list] = None

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────
def _user_dict(u: models.User):
    return {
        "id": u.id,
        "email": u.email,
        "full_name": u.full_name,
        "role": u.role,
        "phone": u.phone,
        "is_active": u.is_active,
        "created_at": u.created_at.isoformat() if u.created_at else None,
    }

def _make_contrat_ref(db: Session):
    import random, string
    while True:
        ref = "CTR-" + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        if not db.query(models.Contrat).filter(models.Contrat.reference == ref).first():
            return ref

def _make_unique_code(db: Session):
    while True:
        code = models.generate_registration_code()
        if not db.query(models.CodeInscription).filter(models.CodeInscription.code == code).first():
            return code

# ─────────────────────────────────────────────
# ROOT
# ─────────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "EXPER IMMO API v2.0", "status": "running"}

# ─────────────────────────────────────────────
# AUTH ENDPOINTS
# ─────────────────────────────────────────────
@app.post("/auth/login")
def login(payload: UserLogin, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    
    # Debug password verification
    try:
        password_valid = auth.verify_password(payload.password, user.hashed_password)
    except Exception as e:
        # Log the error for debugging
        print(f"[DEBUG] Password verification error: {e}")
        print(f"[DEBUG] Hashed password in DB: {user.hashed_password}")
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    
    if not password_valid:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    
    if not user.is_active:
        raise HTTPException(status_code=401, detail="Compte désactivé")

    token = auth.create_access_token({"sub": user.email, "id": user.id, "role": user.role})
    return {"access_token": token, "token_type": "bearer", "user": _user_dict(user)}


@app.post("/auth/register")
def register(payload: UserCreate, db: Session = Depends(database.get_db)):
    """Direct registration — only for admin bootstrap. Regular users use /auth/register-with-code."""
    if db.query(models.User).filter(models.User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    new_user = models.User(
        email=payload.email,
        hashed_password=auth.get_password_hash(payload.password),
        full_name=payload.full_name,
        role=payload.role,
        phone=payload.phone,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    db.add(models.Profile(id=new_user.id, full_name=payload.full_name, role=payload.role, phone=payload.phone))
    db.commit()
    return {"message": "Compte créé avec succès"}


@app.post("/auth/validate-code")
def validate_code(body: dict, db: Session = Depends(database.get_db)):
    """Check if a registration code is valid before showing the form."""
    code_str = (body.get("code") or "").strip().upper()
    record = db.query(models.CodeInscription).filter(
        models.CodeInscription.code == code_str
    ).first()
    if not record:
        raise HTTPException(status_code=404, detail="Code invalide")
    if record.est_utilise:
        raise HTTPException(status_code=400, detail="Ce code a déjà été utilisé")
    return {
        "valid": True,
        "role": record.role,
        "nom_beneficiaire": record.nom_beneficiaire,
        "email_beneficiaire": record.email_beneficiaire,
    }


@app.post("/auth/register-with-code")
def register_with_code(payload: RegisterWithCode, db: Session = Depends(database.get_db)):
    """Registration for proprietaires and locataires using a contract code."""
    code_str = payload.code.strip().upper()
    record = db.query(models.CodeInscription).filter(
        models.CodeInscription.code == code_str
    ).first()
    if not record:
        raise HTTPException(status_code=404, detail="Code d'inscription invalide")
    if record.est_utilise:
        raise HTTPException(status_code=400, detail="Ce code a déjà été utilisé")

    if db.query(models.User).filter(models.User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    # Create user
    new_user = models.User(
        email=payload.email,
        hashed_password=auth.get_password_hash(payload.password),
        full_name=payload.full_name,
        role=record.role,
        phone=payload.phone,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Create profile
    dob = None
    if payload.date_naissance:
        try:
            from datetime import datetime
            dob = datetime.strptime(payload.date_naissance, "%Y-%m-%d").date()
        except Exception:
            pass

    db.add(models.Profile(
        id=new_user.id,
        full_name=payload.full_name,
        phone=payload.phone,
        role=record.role,
        adresse=payload.adresse,
        date_naissance=dob,
        nationalite=payload.nationalite,
        piece_identite_type=payload.piece_type,
        piece_identite_numero=payload.piece_numero,
        statut_dossier="actif",
    ))

    # Create role-specific record
    if record.role == "proprietaire":
        prop = models.Proprietaire(
            user_id=new_user.id,
            type_proprietaire=payload.type_proprietaire or "particulier",
            nom_entreprise=payload.nom_entreprise,
        )
        db.add(prop)
    elif record.role == "locataire":
        loc = models.Locataire(
            user_id=new_user.id,
            profession=payload.profession,
            employeur=payload.employeur,
        )
        db.add(loc)

    # Mark code as used
    record.est_utilise = True
    record.user_id = new_user.id
    db.commit()

    token = auth.create_access_token({"sub": new_user.email, "id": new_user.id, "role": new_user.role})
    return {
        "message": "Compte créé avec succès",
        "access_token": token,
        "token_type": "bearer",
        "user": _user_dict(new_user),
    }


@app.get("/auth/me")
def get_me(current_user: models.User = Depends(get_current_user)):
    return _user_dict(current_user)

# ─────────────────────────────────────────────
# ADMIN — GESTIONNAIRES
# ─────────────────────────────────────────────
@app.get("/admin/gestionnaires")
def list_gestionnaires(
    db: Session = Depends(database.get_db),
    _: models.User = Depends(require_admin)
):
    users = db.query(models.User).filter(
        models.User.role.in_(["gestionnaire", "assistante", "admin"])
    ).order_by(models.User.full_name).all()
    return [_user_dict(u) for u in users]


@app.post("/admin/gestionnaires")
def create_gestionnaire(
    payload: GestionnaireCreate,
    db: Session = Depends(database.get_db),
    _: models.User = Depends(require_admin)
):
    if db.query(models.User).filter(models.User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    full_name = f"{payload.prenom} {payload.nom}".strip()
    new_user = models.User(
        email=payload.email,
        hashed_password=auth.get_password_hash(payload.password),
        full_name=full_name,
        role=payload.role,
        phone=payload.phone,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    db.add(models.Profile(id=new_user.id, full_name=full_name, role=payload.role, phone=payload.phone))
    db.commit()
    return {"message": f"Compte {payload.role} créé", "user": _user_dict(new_user)}


@app.delete("/admin/gestionnaires/{user_id}")
def delete_gestionnaire(
    user_id: str,
    db: Session = Depends(database.get_db),
    current_admin: models.User = Depends(require_admin)
):
    if user_id == current_admin.id:
        raise HTTPException(status_code=400, detail="Impossible de supprimer votre propre compte")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    db.delete(user)
    db.commit()
    return {"message": "Compte supprimé"}

# ─────────────────────────────────────────────
# ADMIN — CONTRATS & CODES
# ─────────────────────────────────────────────
@app.post("/admin/contrats")
def create_contrat(
    payload: ContratCreate,
    db: Session = Depends(database.get_db),
    current_admin: models.User = Depends(require_admin)
):
    # Generate unique registration codes
    code_prop = _make_unique_code(db)
    code_loc = _make_unique_code(db)

    record_prop = models.CodeInscription(
        code=code_prop,
        role="proprietaire",
        nom_beneficiaire=payload.nom_proprietaire,
        email_beneficiaire=payload.email_proprietaire,
    )
    record_loc = models.CodeInscription(
        code=code_loc,
        role="locataire",
        nom_beneficiaire=payload.nom_locataire,
        email_beneficiaire=payload.email_locataire,
    )
    db.add(record_prop)
    db.add(record_loc)
    db.commit()
    db.refresh(record_prop)
    db.refresh(record_loc)

    try:
        debut = date.fromisoformat(payload.date_debut)
        fin = date.fromisoformat(payload.date_fin)
    except ValueError:
        raise HTTPException(status_code=400, detail="Format de date invalide (YYYY-MM-DD)")

    contrat = models.Contrat(
        reference=_make_contrat_ref(db),
        propriete_id=payload.propriete_id,
        nom_proprietaire=payload.nom_proprietaire,
        email_proprietaire=payload.email_proprietaire,
        nom_locataire=payload.nom_locataire,
        email_locataire=payload.email_locataire,
        code_proprietaire_id=record_prop.id,
        code_locataire_id=record_loc.id,
        loyer_mensuel=payload.loyer_mensuel,
        devise=payload.devise,
        caution=payload.caution,
        date_debut=debut,
        date_fin=fin,
        notes=payload.notes,
        created_by=current_admin.id,
    )
    db.add(contrat)
    db.commit()
    db.refresh(contrat)

    return {
        "message": "Contrat créé avec succès",
        "contrat_id": contrat.id,
        "reference": contrat.reference,
        "code_proprietaire": code_prop,
        "code_locataire": code_loc,
    }


@app.get("/admin/contrats")
def list_contrats(
    db: Session = Depends(database.get_db),
    _: models.User = Depends(require_admin)
):
    contrats = db.query(models.Contrat).order_by(models.Contrat.created_at.desc()).all()
    result = []
    for c in contrats:
        prop_titre = None
        if c.propriete_id:
            p = db.query(models.Propriete).filter(models.Propriete.id == c.propriete_id).first()
            if p:
                prop_titre = p.titre
        result.append({
            "id": c.id,
            "reference": c.reference,
            "nom_proprietaire": c.nom_proprietaire,
            "email_proprietaire": c.email_proprietaire,
            "nom_locataire": c.nom_locataire,
            "email_locataire": c.email_locataire,
            "propriete_titre": prop_titre,
            "loyer_mensuel": float(c.loyer_mensuel) if c.loyer_mensuel else 0,
            "devise": c.devise,
            "date_debut": c.date_debut.isoformat() if c.date_debut else None,
            "date_fin": c.date_fin.isoformat() if c.date_fin else None,
            "statut": c.statut,
            "code_proprietaire": c.code_proprietaire.code if c.code_proprietaire else None,
            "code_locataire": c.code_locataire.code if c.code_locataire else None,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        })
    return result


@app.get("/admin/codes")
def list_codes(
    db: Session = Depends(database.get_db),
    _: models.User = Depends(require_admin)
):
    codes = db.query(models.CodeInscription).order_by(models.CodeInscription.created_at.desc()).all()
    return [{
        "id": c.id,
        "code": c.code,
        "role": c.role,
        "nom_beneficiaire": c.nom_beneficiaire,
        "email_beneficiaire": c.email_beneficiaire,
        "est_utilise": c.est_utilise,
        "created_at": c.created_at.isoformat() if c.created_at else None,
    } for c in codes]

# ─────────────────────────────────────────────
# USERS
# ─────────────────────────────────────────────
@app.get("/users")
def get_users(role: Optional[str] = None, db: Session = Depends(database.get_db)):
    query = db.query(models.User)
    if role:
        query = query.filter(models.User.role == role)
    return [_user_dict(u) for u in query.order_by(models.User.full_name).all()]


@app.get("/users/{user_id}")
def get_user(user_id: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    return _user_dict(user)

# ─────────────────────────────────────────────
# PROPERTIES
# ─────────────────────────────────────────────
@app.get("/properties")
def get_properties(
    type_transaction: Optional[str] = None,
    type_bien: Optional[str] = None,
    db: Session = Depends(database.get_db)
):
    query = db.query(models.Propriete).filter(models.Propriete.est_actif == True)
    if type_transaction:
        query = query.filter(models.Propriete.type_transaction == type_transaction)
    if type_bien:
        query = query.filter(models.Propriete.type_bien == type_bien)
    props = query.order_by(models.Propriete.created_at.desc()).all()
    return [_prop_dict(p) for p in props]


@app.get("/properties/{slug}")
def get_property(slug: str, db: Session = Depends(database.get_db)):
    prop = db.query(models.Propriete).filter(models.Propriete.slug == slug).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Propriété non trouvée")
    return _prop_dict(prop)


@app.post("/properties")
def create_property(
    payload: ProprieteCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    import re, datetime

    slug = payload.slug
    if not slug:
        slug = re.sub(r'[^a-z0-9]+', '-', payload.titre.lower()).strip('-')
        base_slug = slug
        count = 1
        while db.query(models.Propriete).filter(models.Propriete.slug == slug).first():
            slug = f"{base_slug}-{count}"
            count += 1

    ref = payload.reference
    if not ref:
        ref = "PROP-" + str(uuid.uuid4())[:8].upper()

    images = payload.images or []

    prop = models.Propriete(
        titre=payload.titre,
        reference=ref,
        slug=slug,
        type_bien=payload.type_bien,
        type_transaction=payload.type_transaction,
        prix=payload.prix,
        devise=payload.devise,
        adresse=payload.adresse,
        ville=payload.ville,
        nb_chambres=payload.nb_chambres,
        nb_salles_bain=payload.nb_salles_bain,
        superficie_m2=payload.superficie_m2,
        description=payload.description,
        statut_bien=payload.statut_bien,
        images=images,
        est_actif=True,
    )

    # Link to proprietaire if user is proprietaire
    if current_user.role == "proprietaire" and current_user.proprietaire:
        prop.proprietaire_id = current_user.proprietaire.id

    db.add(prop)
    db.commit()
    db.refresh(prop)
    return _prop_dict(prop)


@app.put("/properties/{prop_id}")
def update_property(
    prop_id: str,
    payload: dict,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    prop = db.query(models.Propriete).filter(models.Propriete.id == prop_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Propriété non trouvée")

    allowed = {"titre", "description", "type_bien", "type_transaction", "prix", "devise",
               "adresse", "ville", "nb_chambres", "nb_salles_bain", "superficie_m2",
               "statut_bien", "est_actif", "est_vedette", "images"}
    for key, value in payload.items():
        if key in allowed:
            setattr(prop, key, value)
    db.commit()
    return _prop_dict(prop)


def _prop_dict(p: models.Propriete):
    return {
        "id": p.id,
        "reference": p.reference,
        "slug": p.slug,
        "titre": p.titre,
        "description": p.description,
        "type_bien": p.type_bien,
        "type_transaction": p.type_transaction,
        "prix": float(p.prix) if p.prix else 0,
        "devise": p.devise,
        "adresse": p.adresse,
        "ville": p.ville,
        "nb_chambres": p.nb_chambres,
        "nb_salles_bain": p.nb_salles_bain,
        "superficie_m2": float(p.superficie_m2) if p.superficie_m2 else 0,
        "statut_bien": p.statut_bien,
        "est_actif": p.est_actif,
        "est_vedette": p.est_vedette,
        "images": p.images or [],
        "created_at": p.created_at.isoformat() if p.created_at else None,
    }

# ─────────────────────────────────────────────
# IMAGE UPLOAD
# ─────────────────────────────────────────────
ALLOWED_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
MAX_SIZE = 10 * 1024 * 1024  # 10 MB

@app.post("/upload/image")
async def upload_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user)
):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Type non supporté (JPG, PNG, WebP seulement)")

    contents = await file.read()
    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=400, detail="Fichier trop grand (max 10 MB)")

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "jpg"
    filename = f"{uuid.uuid4()}.{ext}"
    dest = UPLOAD_DIR / filename

    with open(dest, "wb") as f:
        f.write(contents)

    base_url = os.getenv("BASE_URL", "")
    url = f"{base_url}/static/uploads/{filename}"
    return {"url": url, "filename": filename}

# ─────────────────────────────────────────────
# AGENTS & ZONES
# ─────────────────────────────────────────────
@app.get("/agents")
def get_agents(db: Session = Depends(database.get_db)):
    return db.query(models.Agent).all()


@app.get("/zones")
def get_zones(db: Session = Depends(database.get_db)):
    return db.query(models.Zone).filter(models.Zone.actif == True).order_by(models.Zone.ordre).all()

# ─────────────────────────────────────────────
# ADMIN STATS
# ─────────────────────────────────────────────
@app.get("/stats/admin")
def get_admin_stats(db: Session = Depends(database.get_db)):
    return {
        "total_proprietes": db.query(models.Propriete).count(),
        "total_gestionnaires": db.query(models.User).filter(models.User.role.in_(["gestionnaire", "assistante"])).count(),
        "total_proprietaires": db.query(models.User).filter(models.User.role == "proprietaire").count(),
        "total_locataires": db.query(models.User).filter(models.User.role == "locataire").count(),
        "contrats_actifs": db.query(models.Contrat).filter(models.Contrat.statut == "actif").count(),
        "revenus_ce_mois": 0,
        "paiements_en_retard": db.query(models.Paiement).filter(models.Paiement.statut == "en_retard").count(),
        "tickets_ouverts": 0,
        "nouveaux_contacts": 0,
    }


@app.get("/locataires")
def get_locataires(db: Session = Depends(database.get_db)):
    locs = db.query(models.Locataire).all()
    result = []
    for l in locs:
        u = l.user
        result.append({
            "id": l.id,
            "user_id": l.user_id,
            "full_name": u.full_name if u else None,
            "email": u.email if u else None,
            "phone": u.phone if u else None,
            "profession": l.profession,
            "employeur": l.employeur,
            "revenu_mensuel": float(l.revenu_mensuel) if l.revenu_mensuel else None,
            "est_actif": l.est_actif,
            "created_at": l.created_at.isoformat() if l.created_at else None,
        })
    return result


@app.get("/proprietaires")
def get_proprietaires(db: Session = Depends(database.get_db)):
    props = db.query(models.Proprietaire).all()
    result = []
    for p in props:
        u = p.user
        result.append({
            "id": p.id,
            "user_id": p.user_id,
            "full_name": u.full_name if u else None,
            "email": u.email if u else None,
            "phone": u.phone if u else None,
            "type_proprietaire": p.type_proprietaire,
            "nom_entreprise": p.nom_entreprise,
            "est_actif": p.est_actif,
            "created_at": p.created_at.isoformat() if p.created_at else None,
        })
    return result


# ─────────────────────────────────────────────
# PAIMENTS ENDPOINTS
# ─────────────────────────────────────────────
class PaiementCreate(BaseModel):
    contrat_id: Optional[str] = None
    montant: float
    devise: str = "HTG"
    date_paiement: Optional[str] = None
    date_echeance: Optional[str] = None
    statut: str = "en_attente"  # en_attente, paye, en_retard
    notes: Optional[str] = None

class PaiementUpdate(BaseModel):
    montant: Optional[float] = None
    devise: Optional[str] = None
    date_paiement: Optional[str] = None
    date_echeance: Optional[str] = None
    statut: Optional[str] = None
    notes: Optional[str] = None

def _paiement_dict(p: models.Paiement):
    return {
        "id": p.id,
        "contrat_id": p.contrat_id,
        "montant": float(p.montant) if p.montant else 0,
        "devise": p.devise,
        "date_paiement": p.date_paiement.isoformat() if p.date_paiement else None,
        "date_echeance": p.date_echeance.isoformat() if p.date_echeance else None,
        "statut": p.statut,
        "notes": p.notes,
        "created_at": p.created_at.isoformat() if p.created_at else None,
    }

@app.get("/paiements")
def list_paiements(
    statut: Optional[str] = None,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Liste tous les paiements (admin/gestionnaire) ou seulement ceux liés au locataire connecté"""
    query = db.query(models.Paiement)
    
    if statut:
        query = query.filter(models.Paiement.statut == statut)
    
    # Si locataire, ne voir que ses paiements
    if current_user.role == "locataire" and current_user.locataire:
        # Trouver les contrats du locataire
        contrat_ids = db.query(models.Contrat.id).filter(
            models.Contrat.locataire_id == current_user.locataire.id
        ).all()
        contrat_ids = [c[0] for c in contrat_ids]
        if contrat_ids:
            query = query.filter(models.Paiement.contrat_id.in_(contrat_ids))
        else:
            return []
    
    paiements = query.order_by(models.Paiement.date_echeance.desc()).all()
    return [_paiement_dict(p) for p in paiements]


@app.post("/paiements")
def create_paiement(
    payload: PaiementCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Créer un nouveau paiement (admin/gestionnaire uniquement)"""
    if current_user.role not in ["admin", "gestionnaire"]:
        raise HTTPException(status_code=403, detail="Accès refusé")
    
    from datetime import datetime
    
    p = models.Paiement(
        id=str(uuid.uuid4()),
        contrat_id=payload.contrat_id,
        montant=payload.montant,
        devise=payload.devise,
        date_paiement=datetime.fromisoformat(payload.date_paiement) if payload.date_paiement else None,
        date_echeance=datetime.fromisoformat(payload.date_echeance) if payload.date_echeance else None,
        statut=payload.statut,
        notes=payload.notes,
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return _paiement_dict(p)


@app.put("/paiements/{paiement_id}")
def update_paiement(
    paiement_id: str,
    payload: PaiementUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Mettre à jour un paiement"""
    if current_user.role not in ["admin", "gestionnaire"]:
        raise HTTPException(status_code=403, detail="Accès refusé")
    
    p = db.query(models.Paiement).filter(models.Paiement.id == paiement_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Paiement non trouvé")
    
    from datetime import datetime
    
    if payload.montant is not None:
        p.montant = payload.montant
    if payload.devise:
        p.devise = payload.devise
    if payload.date_paiement:
        p.date_paiement = datetime.fromisoformat(payload.date_paiement)
    if payload.date_echeance:
        p.date_echeance = datetime.fromisoformat(payload.date_echeance)
    if payload.statut:
        p.statut = payload.statut
    if payload.notes is not None:
        p.notes = payload.notes
    
    db.commit()
    db.refresh(p)
    return _paiement_dict(p)


@app.delete("/paiements/{paiement_id}")
def delete_paiement(
    paiement_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Supprimer un paiement (admin uniquement)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Accès refusé")
    
    p = db.query(models.Paiement).filter(models.Paiement.id == paiement_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Paiement non trouvé")
    
    db.delete(p)
    db.commit()
    return {"message": "Paiement supprimé"}


@app.get("/paiements/stats")
def paiements_stats(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Statistiques des paiements"""
    from datetime import datetime
    
    now = datetime.now()
    first_day = datetime(now.year, now.month, 1).date()
    
    # Compter par statut
    payes = db.query(models.Paiement).filter(models.Paiement.statut == "paye").count()
    attente = db.query(models.Paiement).filter(models.Paiement.statut == "en_attente").count()
    retard = db.query(models.Paiement).filter(models.Paiement.statut == "en_retard").count()
    
    # Revenus du mois
    revenus = db.query(models.Paiement).filter(
        models.Paiement.statut == "paye",
        models.Paiement.date_paiement >= first_day
    ).all()
    total_revenus = sum(float(r.montant) for r in revenus) if revenus else 0
    
    return {
        "payes": payes,
        "en_attente": attente,
        "en_retard": retard,
        "revenus_mois": total_revenus,
        "devise": "HTG"
    }


# ─────────────────────────────────────────────
# AGENTS ENDPOINTS
# ─────────────────────────────────────────────
class AgentCreate(BaseModel):
    nom: str
    prenom: str
    titre: Optional[str] = None
    telephone: Optional[str] = None
    email: Optional[str] = None
    photo_url: Optional[str] = None
    ordre: int = 0

class AgentUpdate(BaseModel):
    nom: Optional[str] = None
    prenom: Optional[str] = None
    titre: Optional[str] = None
    telephone: Optional[str] = None
    email: Optional[str] = None
    photo_url: Optional[str] = None
    ordre: Optional[int] = None

def _agent_dict(a: models.Agent):
    return {
        "id": a.id,
        "nom": a.nom,
        "prenom": a.prenom,
        "titre": a.titre,
        "telephone": a.telephone,
        "email": a.email,
        "photo_url": a.photo_url,
        "ordre": a.ordre,
        "created_at": a.created_at.isoformat() if a.created_at else None,
    }

@app.get("/agents")
def list_agents(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Liste tous les agents"""
    agents = db.query(models.Agent).order_by(models.Agent.ordre).all()
    return [_agent_dict(a) for a in agents]


@app.post("/agents")
def create_agent(
    payload: AgentCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Créer un nouvel agent (admin uniquement)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Accès refusé")
    
    agent = models.Agent(
        id=str(uuid.uuid4()),
        nom=payload.nom,
        prenom=payload.prenom,
        titre=payload.titre,
        telephone=payload.telephone,
        email=payload.email,
        photo_url=payload.photo_url,
        ordre=payload.ordre,
    )
    db.add(agent)
    db.commit()
    db.refresh(agent)
    return _agent_dict(agent)


@app.put("/agents/{agent_id}")
def update_agent(
    agent_id: str,
    payload: AgentUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Mettre à jour un agent (admin uniquement)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Accès refusé")
    
    agent = db.query(models.Agent).filter(models.Agent.id == agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent non trouvé")
    
    if payload.nom is not None:
        agent.nom = payload.nom
    if payload.prenom is not None:
        agent.prenom = payload.prenom
    if payload.titre is not None:
        agent.titre = payload.titre
    if payload.telephone is not None:
        agent.telephone = payload.telephone
    if payload.email is not None:
        agent.email = payload.email
    if payload.photo_url is not None:
        agent.photo_url = payload.photo_url
    if payload.ordre is not None:
        agent.ordre = payload.ordre
    
    db.commit()
    db.refresh(agent)
    return _agent_dict(agent)


@app.delete("/agents/{agent_id}")
def delete_agent(
    agent_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Supprimer un agent (admin uniquement)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Accès refusé")
    
    agent = db.query(models.Agent).filter(models.Agent.id == agent_id).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Agent non trouvé")
    
    db.delete(agent)
    db.commit()
    return {"message": "Agent supprimé"}


# ─────────────────────────────────────────────
# ADMIN SETUP ENDPOINT (for Render free tier - no shell access)
# ─────────────────────────────────────────────
class SetupAdminRequest(BaseModel):
    secret: str
    email: str = "admin@experimmo.com"
    password: str = "Admin@Exp2024!"
    full_name: str = "Administrateur EXPERIMMO"

@app.post("/setup/admin")
def setup_admin(payload: SetupAdminRequest, db: Session = Depends(database.get_db)):
    """
    Endpoint to create or reset admin user.
    Requires SECRET_KEY as 'secret' parameter for security.
    """
    expected_secret = os.getenv("SECRET_KEY", "dev-secret-key")
    if payload.secret != expected_secret:
        raise HTTPException(status_code=403, detail="Invalid secret key")
    
    # Check if admin exists
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    
    if existing:
        # Reset password
        existing.hashed_password = auth.get_password_hash(payload.password)
        db.commit()
        return {
            "message": "Admin password reset successfully",
            "email": payload.email,
            "password": payload.password,
            "action": "password_reset"
        }
    
    # Create new admin
    user = models.User(
        id=str(uuid.uuid4()),
        email=payload.email,
        hashed_password=auth.get_password_hash(payload.password),
        full_name=payload.full_name,
        role="admin",
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create profile
    profile = models.Profile(
        id=user.id,
        full_name=payload.full_name,
        role="admin"
    )
    db.add(profile)
    db.commit()
    
    return {
        "message": "Admin created successfully",
        "email": payload.email,
        "password": payload.password,
        "action": "created"
    }


@app.get("/health")
def health_check(db: Session = Depends(database.get_db)):
    """Health check endpoint"""
    try:
        # Check database connection - SQLAlchemy 2.0 compatible
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    # Check if admin exists
    admin_count = db.query(models.User).filter(models.User.role == "admin").count()
    
    return {
        "status": "ok",
        "database": db_status,
        "admin_users": admin_count,
        "secret_key_set": bool(os.getenv("SECRET_KEY"))
    }


class DebugLoginRequest(BaseModel):
    email: str
    password: str

@app.post("/debug/login")
def debug_login(payload: DebugLoginRequest, db: Session = Depends(database.get_db)):
    """Debug endpoint to check login issues"""
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    
    if not user:
        return {"error": "User not found", "email": payload.email}
    
    # Check password
    verify_error = None
    try:
        is_valid = auth.verify_password(payload.password, user.hashed_password)
    except Exception as e:
        is_valid = False
        verify_error = str(e)
    
    # Return debug info (without exposing too much)
    return {
        "user_found": True,
        "email": user.email,
        "role": user.role,
        "is_active": user.is_active,
        "password_valid": is_valid,
        "password_hash_prefix": user.hashed_password[:30] + "..." if user.hashed_password else None,
        "hash_length": len(user.hashed_password) if user.hashed_password else 0,
        "verify_error": verify_error if verify_error else None
    }


if __name__ == "__main__":
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True)
