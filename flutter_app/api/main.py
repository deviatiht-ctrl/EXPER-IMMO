from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import os
from supabase import create_client, Client
from datetime import datetime

app = FastAPI(title="EXPERIMMO API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase client
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://fxykqzjzqzjzqzjzqz.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Pydantic models
class LoginRequest(BaseModel):
    email: str
    password: str

class UserProfile(BaseModel):
    id: str
    email: str
    role: str
    full_name: Optional[str] = None
    phone: Optional[str] = None

# Auth endpoints
@app.post("/auth/login")
async def login(request: LoginRequest):
    try:
        auth = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        if auth.user:
            return {
                "user": {
                    "id": auth.user.id,
                    "email": auth.user.email,
                    "role": auth.user.user_metadata.get("role", "locataire")
                },
                "session": {
                    "access_token": auth.session.access_token,
                    "refresh_token": auth.session.refresh_token
                }
            }
        else:
            raise HTTPException(status_code=401, detail="Login failed")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/auth/logout")
async def logout():
    try:
        supabase.auth.sign_out()
        return {"message": "Logged out successfully"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Profile endpoints
@app.get("/profile/{user_id}")
async def get_profile(user_id: str):
    try:
        profile = supabase.from("profiles").select("*").eq("id", user_id).single()
        if profile.data:
            return profile.data
        else:
            raise HTTPException(status_code=404, detail="Profile not found")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Proprietaire endpoints
@app.get("/proprietaire/{user_id}")
async def get_proprietaire(user_id: str):
    try:
        data = supabase.from("proprietaires").select(
            "*, user:profiles!proprietaires_user_id_fkey(full_name, email, phone)"
        ).eq("user_id", user_id).single()
        return data.data if data.data else {}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/proprietaire/{user_id}/proprietes")
async def get_proprietaire_proprietes(user_id: str):
    try:
        data = supabase.from("proprietes").select("*").eq("proprietaire_id", user_id)
        return data.data if data.data else []
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Locataire endpoints
@app.get("/locataire/{user_id}")
async def get_locataire(user_id: str):
    try:
        data = supabase.from("locataires").select(
            "*, user:profiles!locataires_user_id_fkey(full_name, email, phone)"
        ).eq("user_id", user_id).single()
        return data.data if data.data else {}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/locataire/{user_id}/contrat")
async def get_locataire_contrat(user_id: str):
    try:
        data = supabase.from("contrats").select(
            "*, propriete:proprietes(titre, adresse), locataire:locataires(user:profiles!locataires_user_id_fkey(full_name))"
        ).eq("locataire_id", user_id).eq("statut", "actif").single()
        return data.data if data.data else {}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Admin endpoints
@app.get("/admin/stats")
async def get_admin_stats():
    try:
        stats = {}
        tables = ["proprietaires", "locataires", "proprietes", "contrats", "paiements"]
        for table in tables:
            count = supabase.from(table).select("*", count="exact")
            stats[table] = count.count if count.count else 0
        return stats
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/admin/proprietaires")
async def get_admin_proprietaires():
    try:
        data = supabase.from("proprietaires").select(
            "*, user:profiles!proprietaires_user_id_fkey(full_name, email, phone)"
        )
        return data.data if data.data else []
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/admin/locataires")
async def get_admin_locataires():
    try:
        data = supabase.from("locataires").select(
            "*, user:profiles!locataires_user_id_fkey(full_name, email, phone)"
        )
        return data.data if data.data else []
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/admin/proprietes")
async def get_admin_proprietes():
    try:
        data = supabase.from("proprietes").select("*, zones(nom)")
        return data.data if data.data else []
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/admin/contrats")
async def get_admin_contrats():
    try:
        data = supabase.from("contrats").select(
            "*, locataire:locataires(user:profiles!locataires_user_id_fkey(full_name)), propriete:proprietes(titre)"
        )
        return data.data if data.data else []
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Health check
@app.get("/")
async def root():
    return {"message": "EXPERIMMO API is running", "status": "active"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
