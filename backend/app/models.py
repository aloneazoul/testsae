# backend/app/models.py
from sqlalchemy import Column, Integer, String, Enum, Date, DateTime, ForeignKey, text
from sqlalchemy.orm import relationship
from .database import Base

class Utilisateur(Base):
    __tablename__ = "Utilisateurs"

    id_utilisateur = Column(Integer, primary_key=True, index=True)
    nom = Column(String(100), nullable=False)
    prenom = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    mot_de_passe = Column(String(255), nullable=False)
    role = Column(Enum('etudiant', 'enseignant', 'bibliothecaire'), nullable=False)
    date_creation = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"))

class Livre(Base):
    __tablename__ = "Livres"

    id_livre = Column(Integer, primary_key=True, index=True)
    isbn = Column(String(13), unique=True)
    titre = Column(String(255), nullable=False)
    auteur = Column(String(255))
    editeur = Column(String(100))
    annee_publication = Column(Integer) # YEAR en SQL correspond souvent à Integer
    categorie = Column(String(100))

    exemplaires = relationship("Exemplaire", back_populates="livre")

class Exemplaire(Base):
    __tablename__ = "Exemplaires"

    id_exemplaire = Column(Integer, primary_key=True, index=True)
    id_livre = Column(Integer, ForeignKey("Livres.id_livre"), nullable=False)
    code_barre = Column(String(100), unique=True)
    statut_exemplaire = Column(Enum('disponible', 'emprunte', 'perdu'), default='disponible', nullable=False)
    etat_physique = Column(String(255))

    livre = relationship("Livre", back_populates="exemplaires")

class Emprunt(Base):
    __tablename__ = "Emprunts"

    id_emprunt = Column(Integer, primary_key=True, index=True)
    id_exemplaire = Column(Integer, ForeignKey("Exemplaires.id_exemplaire"), nullable=False)
    id_utilisateur = Column(Integer, ForeignKey("Utilisateurs.id_utilisateur"), nullable=False)
    date_emprunt = Column(DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False)
    date_retour_prevue = Column(Date, nullable=False)
    date_retour_reelle = Column(DateTime, nullable=True)
    statut_emprunt = Column(Enum('en_cours', 'termine', 'en_retard'), default='en_cours', nullable=False)

    exemplaire = relationship("Exemplaire")
    utilisateur = relationship("Utilisateur")