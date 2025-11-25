# routers/trips.py

from fastapi import APIRouter, Depends, HTTPException, Form, File, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone

import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Trips"])


# ============================================================
# 1. CRÉER UN VOYAGE
# ============================================================
@router.post("/trips")
def create_trip(
    trip_title: str = Form(...),
    trip_description: str = Form(None),
    start_date: str = Form(...),
    end_date: str = Form(...),
    is_public: bool = Form(True),
    banner: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = models.Trip(
        trip_title=trip_title,
        trip_description=trip_description,
        start_date=start_date,
        end_date=end_date,
        is_public_flag="Y" if is_public else "N",
        user_id=current_user.user_id,
        created_by=current_user.user_id,
        last_modified_by=current_user.user_id,
        last_modification_date=datetime.now(timezone.utc)
    )

    db.add(trip)
    db.commit()
    db.refresh(trip)

    return {"message": "Voyage créé", "trip_id": trip.trip_id}


# ============================================================
# 2. METTRE À JOUR UN VOYAGE
# ============================================================
@router.put("/trips/{trip_id}")
def update_trip(
    trip_id: int,
    trip_title: str = None,
    trip_description: str = None,
    start_date: str = None,
    end_date: str = None,
    is_public: bool = None,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux modifier que tes propres voyages")

    # Sauvegarde dans l'historique
    hist = models.TripHistory(
        trip_id=trip.trip_id,
        trip_title=trip.trip_title,
        trip_description=trip.trip_description,
        start_date=trip.start_date,
        end_date=trip.end_date,
        is_public_flag=trip.is_public_flag,
        changed_by=current_user.user_id,
    )
    db.add(hist)

    # Mise à jour des champs
    if trip_title is not None:
        trip.trip_title = trip_title
    if trip_description is not None:
        trip.trip_description = trip_description
    if start_date is not None:
        trip.start_date = start_date
    if end_date is not None:
        trip.end_date = end_date
    if is_public is not None:
        trip.is_public_flag = "Y" if is_public else "N"

    trip.last_modified_by = current_user.user_id
    trip.last_modification_date = datetime.now(timezone.utc)

    db.commit()
    return {"message": "Voyage mis à jour"}


# ============================================================
# 3. SUPPRIMER UN VOYAGE
# ============================================================
@router.delete("/trips/{trip_id}")
def delete_trip(
    trip_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux supprimer que tes voyages")

    # Suppression cascade automatique (trip_places)
    db.delete(trip)
    db.commit()

    return {"message": "Voyage supprimé"}


# ============================================================
# 4. VOIR L'HISTORIQUE D’UN VOYAGE
# ============================================================
@router.get("/trips/{trip_id}/history")
def trip_history(
    trip_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux voir que l’historique de tes voyages")

    hist = db.query(models.TripHistory).filter_by(trip_id=trip_id).all()

    return [{"changed_at": h.changed_at, "changed_by": h.changed_by,
             "title": h.trip_title, "description": h.trip_description,
             "start_date": h.start_date, "end_date": h.end_date,
             "is_public_flag": h.is_public_flag} for h in hist]


# ============================================================
# 5. LISTE DE MES VOYAGES
# ============================================================
@router.get("/trips/my")
def get_my_trips(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trips = db.query(models.Trip).filter_by(user_id=current_user.user_id).all()
    return trips


# ============================================================
# 6. LISTE DES VOYAGES PUBLICS
# ============================================================
@router.get("/trips/public")
def get_public_trips(
    db: Session = Depends(database.get_db),
):
    trips = db.query(models.Trip).filter_by(is_public_flag="Y").all()
    return trips


# ============================================================
# 7. OBTENIR UN TRIP (PUBLIC OU PROPRIÉTAIRE)
# ============================================================
@router.get("/trips/{trip_id}")
def get_trip(
    trip_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    # Privé → seulement le propriétaire peut le voir
    if trip.is_public_flag == "N" and trip.user_id != current_user.user_id:
        raise HTTPException(403, "Voyage privé")

    return trip


# ============================================================
# 8. AJOUTER UN LIEU DANS UN VOYAGE
# ============================================================
@router.post("/trips/{trip_id}/places")
def add_place_to_trip(
    trip_id: int,
    place_id: int,
    visited_at: str = None,
    ordinal: int = None,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux modifier que tes voyages")

    # Vérifier si ce lieu existe
    place = db.query(models.Place).filter_by(place_id=place_id).first()
    if not place:
        raise HTTPException(404, "Lieu introuvable")

    tp = models.TripPlace(
        trip_id=trip_id,
        place_id=place_id,
        visited_at=visited_at,
        ordinal=ordinal
    )
    db.add(tp)
    db.commit()

    return {"message": "Lieu ajouté au voyage"}


# ============================================================
# 9. SUPPRIMER UN LIEU DU VOYAGE
# ============================================================
@router.delete("/trips/{trip_id}/places/{place_id}")
def remove_place_from_trip(
    trip_id: int,
    place_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux modifier que tes voyages")

    tp = db.query(models.TripPlace).filter_by(
        trip_id=trip_id,
        place_id=place_id
    ).first()

    if not tp:
        raise HTTPException(404, "Lieu introuvable dans le voyage")

    db.delete(tp)
    db.commit()

    return {"message": "Lieu retiré du voyage"}


# ============================================================
# 10. LISTER LES LIEUX DU VOYAGE
# ============================================================
@router.get("/trips/{trip_id}/places")
def list_trip_places(
    trip_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.is_public_flag == "N" and trip.user_id != current_user.user_id:
        raise HTTPException(403, "Voyage privé")

    res = db.query(models.TripPlace).filter_by(trip_id=trip_id).order_by(models.TripPlace.ordinal).all()

    return res
