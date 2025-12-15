from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

# Chargement du fichier .env
load_dotenv()

# Récupération de l'URL de la DB depuis .env
DATABASE_URL = os.getenv("DATABASE_URL")
print("DATABASE_URL chargée :", DATABASE_URL)

# Création de l'engine SQLAlchemy
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # Vérifie que la connexion est toujours valide
)

# Création d'une session locale
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dépendance FastAPI pour injecter la session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()