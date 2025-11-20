from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import sys

# ---- 1️⃣ Récupérer le mot de passe depuis le secret Docker ----
SECRET_PATH = "/run/secrets/db_password"

if os.path.exists(SECRET_PATH):
    with open(SECRET_PATH, "r") as f:
        DB_PASSWORD = f.read().strip()
    print("🔐 Mot de passe DB chargé depuis le secret Docker.", flush=True)
else:
    print("⚠️ Secret Docker non trouvé, fallback (DEV MODE)", flush=True)
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")

# ---- 2️⃣ Construire la vraie DATABASE_URL utilisée dans Swarm ----
DATABASE_URL = (
    f"mysql+pymysql://root:{DB_PASSWORD}@localhost:3306/spotshare"
)

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
