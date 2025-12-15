from sqlalchemy.orm import Session
from app.models.user import User  # modèle SQLAlchemy
from app.schemas.user import UserCreate, UserUpdate

# --- Création d'un utilisateur ---
def create_user(db: Session, user_data: UserCreate) -> User:
    db_user = User(
        nom=user_data.nom,
        prenom=user_data.prenom,
        email=user_data.email,
        role=user_data.role,
        mot_de_passe=user_data.mot_de_passe
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# --- Récupération de tous les utilisateurs ---
def get_users(db: Session) -> list[User]:
    return db.query(User).all()

# --- Récupération d'un utilisateur par ID ---
def get_user_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id_utilisateur == user_id).first()

# --- Mise à jour d'un utilisateur ---
def update_user(db: Session, user_id: int, user_data: UserUpdate) -> User | None:
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return None

    for field, value in user_data.dict(exclude_unset=True).items():
        setattr(db_user, field, value)

    db.commit()
    db.refresh(db_user)
    return db_user

# --- Suppression d'un utilisateur ---
def delete_user(db: Session, user_id: int) -> bool:
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        return False
    db.delete(db_user)
    db.commit()
    return True
