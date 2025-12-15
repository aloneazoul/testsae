from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import crud, models, schemas, database

router = APIRouter(
    prefix="/livres",
    tags=["livres"]
)

# Route pour récupérer la liste des livres
@router.get("/", response_model=List[schemas.Livre])
def read_livres(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db)):
    livres = crud.get_livres(db, skip=skip, limit=limit)
    return livres

# Route pour récupérer un livre spécifique
@router.get("/{livre_id}", response_model=schemas.Livre)
def read_livre(livre_id: int, db: Session = Depends(database.get_db)):
    db_livre = crud.get_livre(db, livre_id=livre_id)
    if db_livre is None:
        # CORRECTION ICI : suppression de "Jf" avant detail=
        raise HTTPException(status_code=404, detail="Livre introuvable")
    return db_livre
# Route pour ajouter un livre
@router.post("/", response_model=schemas.Livre)
def create_livre(livre: schemas.LivreCreate, db: Session = Depends(database.get_db)):
    # Ici, vous pourriez ajouter une vérification si l'ISBN existe déjà
    return crud.create_livre(db=db, livre=livre)