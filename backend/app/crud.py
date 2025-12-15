from sqlalchemy.orm import Session
from . import models, schemas

# Récupérer tous les livres
def get_livres(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Livre).offset(skip).limit(limit).all()

# Récupérer un livre par son ID
def get_livre(db: Session, livre_id: int):
    return db.query(models.Livre).filter(models.Livre.id_livre == livre_id).first()

# Créer un nouveau livre
def create_livre(db: Session, livre: schemas.LivreCreate):
    db_livre = models.Livre(**livre.dict())
    db.add(db_livre)
    db.commit()
    db.refresh(db_livre)
    return db_livre

# --- CRUD UTILISATEURS ---

def get_utilisateur(db: Session, utilisateur_id: int):
    return db.query(models.Utilisateur).filter(models.Utilisateur.id_utilisateur == utilisateur_id).first()

def get_utilisateur_by_email(db: Session, email: str):
    return db.query(models.Utilisateur).filter(models.Utilisateur.email == email).first()

def create_utilisateur(db: Session, utilisateur: schemas.UtilisateurCreate):
    # NOTE : Pour l'instant on stocke le mot de passe en clair pour faire simple.
    # Pour la sécurité (étape ultérieure), il faudra le hacher (bcrypt).
    db_utilisateur = models.Utilisateur(
        nom=utilisateur.nom,
        prenom=utilisateur.prenom,
        email=utilisateur.email,
        mot_de_passe=utilisateur.mot_de_passe, 
        role=utilisateur.role
    )
    db.add(db_utilisateur)
    db.commit()
    db.refresh(db_utilisateur)
    return db_utilisateur