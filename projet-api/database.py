from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import sys

# ---- 1️⃣ Récupérer le mot de passe depuis le secret Docker ----
SECRET_PATH = "/run/secrets/db_password"
# Variables par défaut (seront écrasées selon l'OS)
db_port = "3306"
default_password = ""

if os.path.exists(SECRET_PATH):
    # Cas Docker Swarm / Prod
    with open(SECRET_PATH, "r") as f:
        DB_PASSWORD = f.read().strip()
    # En prod Docker, on utilise souvent le nom du service "db" et le port 3306
    db_host = "db" 
    db_port = "3306" 
    print("🔐 Mot de passe DB chargé depuis le secret Docker.", flush=True)

else:
    # Cas DEV LOCAL (Mac vs Windows)
    print("⚠️ Secret Docker non trouvé, passage en mode DEV LOCAL", flush=True)
    
    db_host = "localhost"

    if sys.platform == "darwin":
        # --- CONFIG MAC (MAMP ?) ---
        print("🍏 Environnement détecté : macOS", flush=True)
        default_password = "root"
        db_port = "8889"
    elif sys.platform == "win32":
        # --- CONFIG WINDOWS (WAMP / XAMPP ?) ---
        print("🪟 Environnement détecté : Windows", flush=True)
        default_password = "" # Souvent vide sur Windows par défaut
        db_port = "3306"
    else:
        # --- CONFIG LINUX / AUTRE ---
        print("🐧 Environnement détecté : Linux/Autre", flush=True)
        default_password = "root"
        db_port = "3306"

    # On laisse la possibilité de surcharger via variable d'environnement si besoin
    DB_PASSWORD = os.getenv("DB_PASSWORD", default_password)


# ---- 2️⃣ Construire la DATABASE_URL dynamique ----
DATABASE_URL = f"mysql+pymysql://root:{DB_PASSWORD}@{db_host}:{db_port}/spotshare"

print(f"📦 DATABASE_URL = {DATABASE_URL}", flush=True)

# ---- 3️⃣ Configuration SQLAlchemy ----
try:
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base = declarative_base()
except Exception as e:
    print(f"❌ ERREUR DB: {e}", flush=True)
    sys.exit(1)

# ---- 4️⃣ Dépendance FastAPI ----
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
