# EXPERIMMO FastAPI Backend

API FastAPI ki travay ak Supabase pou aplikasyon Flutter la.

## Enstalasyon

1. **Enstalasyon Python**
   ```bash
   # Verify Python 3.8+
   python --version
   
   # Create virtual environment
   python -m venv venv
   
   # Activate virtual environment
   # Windows:
   venv\Scripts\activate
   # Linux/Mac:
   source venv/bin/activate
   ```

2. **Enstalasyon depandans**
   ```bash
   pip install -r requirements.txt
   ```

3. **Konfigirasyon anviwònman**
   ```bash
   # Create .env file
   echo "SUPABASE_URL=votre_supabase_url" > .env
   echo "SUPABASE_ANON_KEY=votre_supabase_anon_key" >> .env
   ```

4. **Lanse API**
   ```bash
   python main.py
   ```
   
   API la ap kouri sou: `http://localhost:8000`

## Dokimantasyon API

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Endpoints prensipal

### Auth
- `POST /auth/login` - Koneksyon itilizatè
- `POST /auth/logout` - Dekoneksyon

### Admin
- `GET /admin/stats` - Statistik admin
- `GET /admin/proprietaires` - Lis propriyetè
- `GET /admin/locataires` - Lis lokatè
- `GET /admin/proprietes` - Lis pwopriyete
- `GET /admin/contrats` - Lis kontra

### Proprietaire
- `GET /proprietaire/{user_id}` - Profil propriyetè
- `GET /proprietaire/{user_id}/proprietes` - Biyen propriyetè

### Locataire
- `GET /locataire/{user_id}` - Profil lokatè
- `GET /locataire/{user_id}/contrat` - Kontra aktif lokatè

### Profile
- `GET /profile/{user_id}` - Profil itilizatè

## Test API

```bash
# Test login
curl -X POST "http://localhost:8000/auth/login" \
     -H "Content-Type: application/json" \
     -d '{"email": "test@example.com", "password": "password"}'

# Test admin stats
curl "http://localhost:8000/admin/stats"

# Test profile
curl "http://localhost:8000/profile/user_id_here"
```

## Deploymann

### Docker
```bash
# Build image
docker build -t experimmo-api .

# Run container
docker run -p 8000:8000 experimmo-api
```

### Production
```bash
# Install gunicorn
pip install gunicorn

# Run with gunicorn
gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --host 0.0.0.0 --port 8000
```

## Sekirite

- API itilize menm Supabase keys ki site web la
- CORS pèmèt tout orijin pou devlopman
- An production, limite CORS ak ajoute autentikasyon

## Troubleshooting

1. **Supabase connection error**
   - Verify URL and keys in .env
   - Check Supabase project status

2. **CORS errors**
   - Verify frontend is calling correct URL
   - Check CORS middleware settings

3. **Module not found**
   - Activate virtual environment
   - Install requirements.txt

4. **Port already in use**
   - Change port in main.py or stop other service
