"""
Run once after deployment to create the first admin account.
Usage: python -m backend.create_admin
"""
import os
from dotenv import load_dotenv

load_dotenv()

from . import database, models, auth

def create_admin():
    db = database.SessionLocal()
    try:
        email    = os.getenv("ADMIN_EMAIL",    "admin@experimmo.com")
        password = os.getenv("ADMIN_PASSWORD", "Admin@Exp2024!")
        name     = os.getenv("ADMIN_NAME",     "Administrateur EXPERIMMO")

        existing = db.query(models.User).filter(models.User.email == email).first()
        if existing:
            print(f"[INFO] Admin already exists: {email}")
            return

        models.Base.metadata.create_all(bind=database.engine)

        user = models.User(
            email=email,
            hashed_password=auth.get_password_hash(password),
            full_name=name,
            role="admin",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        db.add(models.Profile(id=user.id, full_name=name, role="admin"))
        db.commit()

        print(f"[OK] Admin created: {email} / {password}")
        print("[!] Change the password immediately after first login.")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
