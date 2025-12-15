from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import crud, models, schemas, database

router = APIRouter(
    prefix="/utilisateurs",
    tags=["utilisateurs"]
)

@router.post("/", response_model=schemas.Utilisateur)
def create_utilisateur(utilisateur: schemas.UtilisateurCreate, db: Session = Depends(database.get_db)):
    db_user = crud.get_utilisateur_by_email(db, email=utilisateur.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Cet email est déjà utilisé")
    return crud.create_utilisateur(db=db, utilisateur=utilisateur)

@router.get("/{utilisateur_id}", response_model=schemas.Utilisateur)
def read_utilisateur(utilisateur_id: int, db: Session = Depends(database.get_db)):
    db_user = crud.get_utilisateur(db, utilisateur_id=utilisateur_id)
    if db_user is None:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    return db_user