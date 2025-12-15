from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

# --- Schémas de Base (pour les données qui entrent/sortent) ---
class UserBase(BaseModel):
    """Schéma de base pour les attributs communs aux utilisateurs."""
    nom: str
    prenom: str
    email: EmailStr
    role: str # correspond à ENUM('etudiant', 'enseignant', 'bibliothecaire')

# --- Schémas pour la Création et la Mise à jour ---
class UserCreate(UserBase):
    """Schéma pour la création d'un nouvel utilisateur."""
    mot_de_passe: str

class UserUpdate(UserBase):
    """Schéma pour la mise à jour d'un utilisateur."""
    nom: Optional[str] = None
    prenom: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    mot_de_passe: Optional[str] = None


# --- Schémas de Sortie (pour les données envoyées au client) ---
class UserOut(UserBase):
    """Schéma pour les données d'utilisateur renvoyées au client."""
    id_utilisateur: int
    date_creation: datetime
    
    class Config:
        """Configuration pour permettre la conversion depuis un modèle ORM SQLAlchemy."""
        orm_mode = True

# --- Schéma simplifié ---
class UserSimplifiedOut(BaseModel):
    """Un schéma de sortie plus simple."""
    id: int
    nom_complet: str
    email: EmailStr

    @classmethod
    def from_orm(cls, user):
        """Méthode pour créer l'objet à partir de l'instance SQLAlchemy."""
        return cls(
            id=user.id_utilisateur,
            nom_complet=f"{user.prenom} {user.nom}",
            email=user.email
        )

    class Config:
        # Permet à FastAPI/Pydantic de gérer l'objet ORM
        orm_mode = True