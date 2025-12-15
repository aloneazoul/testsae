from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.controllers.user_controller import create_user, get_users, get_user_by_id, update_user, delete_user
from app.schemas.user import UserCreate, UserUpdate, UserOut

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

# --- Créer un utilisateur ---
@router.post("/", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user_endpoint(user: UserCreate, db: Session = Depends(get_db)):
    db_user = create_user(db, user)
    return db_user

# --- Récupérer tous les utilisateurs ---
@router.get("/", response_model=List[UserOut])
def get_users_endpoint(db: Session = Depends(get_db)):
    users = get_users(db)
    return users

# --- Récupérer un utilisateur par ID ---
@router.get("/{user_id}", response_model=UserOut)
def get_user_endpoint(user_id: int, db: Session = Depends(get_db)):
    db_user = get_user_by_id(db, user_id)
    if not db_user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    return db_user

# --- Mettre à jour un utilisateur ---
@router.put("/{user_id}", response_model=UserOut)
def update_user_endpoint(user_id: int, user: UserUpdate, db: Session = Depends(get_db)):
    db_user = update_user(db, user_id, user)
    if not db_user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    return db_user

# --- Supprimer un utilisateur ---
@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_endpoint(user_id: int, db: Session = Depends(get_db)):
    success = delete_user(db, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    return None
