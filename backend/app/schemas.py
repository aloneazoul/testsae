from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# Schéma de base avec les champs communs
class LivreBase(BaseModel):
    isbn: str
    titre: str
    auteur: Optional[str] = None
    editeur: Optional[str] = None
    annee_publication: Optional[int] = None
    categorie: Optional[str] = None

# Schéma pour la création (hérite de base)
class LivreCreate(LivreBase):
    pass

# Schéma pour la lecture (inclut l'ID généré par la DB)
class Livre(LivreBase):
    id_livre: int

    class Config:
        from_attributes = True  # Permet de lire les objets SQLAlchemy

# --- SCHEMAS UTILISATEURS ---

class UtilisateurBase(BaseModel):
    nom: str
    prenom: str
    email: str
    role: str  # On pourrait utiliser un Enum ici aussi

class UtilisateurCreate(UtilisateurBase):
    mot_de_passe: str

class Utilisateur(UtilisateurBase):
    id_utilisateur: int
    date_creation: datetime

    class Config:
        from_attributes = True