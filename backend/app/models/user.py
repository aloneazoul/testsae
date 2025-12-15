from sqlalchemy import Column, Integer, String, Enum, DateTime, func
from app.db.base import Base

class User(Base):
    __tablename__ = "utilisateurs"

    id_utilisateur = Column(Integer, primary_key=True, index=True) 
    nom = Column(String(100), nullable=False)
    prenom = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True, index=True)
    mot_de_passe = Column(String(255), nullable=False)
    role = Column(Enum('etudiant', 'enseignant', 'bibliothecaire', name='user_roles'), nullable=False)
    date_creation = Column(DateTime, default=func.now())