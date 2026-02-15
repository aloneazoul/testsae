# routers/trips.py

from fastapi import APIRouter, Depends, HTTPException, Form, File, UploadFile
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone
import cloudinary
import cloudinary.uploader
import os
import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Trips"])

# Config Cloudinary
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "dio0m73b8"),
    api_key=os.getenv("CLOUDINARY_API_KEY", "176583934591119"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET", "EwbWKNCXrzvYNVNGEG72c0nfBF0"),
)


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
    banner_file: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    # 1. Upload de la bannière
    banner_url = None
    if banner_file:
        try:
            print(f"📤 Tentative upload banner: {banner_file.filename}")
            upload_result = cloudinary.uploader.upload(
                banner_file.file,
                folder="trips/banners",
                resource_type="image"
            )
            banner_url = upload_result.get("secure_url")
            print(f"✅ Banner uploadée: {banner_url}")
        except Exception as e:
            print(f"⚠️ Erreur upload banner: {e}")

    # 2. Création
    trip = models.Trip(
        trip_title=trip_title,
        trip_description=trip_description,
        start_date=start_date,
        end_date=end_date,
        is_public_flag="Y" if is_public else "N",
        user_id=current_user.user_id,
        banner=banner_url,
        created_by=current_user.user_id,
        last_modified_by=current_user.user_id,
        last_modification_date=datetime.now(timezone.utc)
    )

    db.add(trip)
    db.commit()
    db.refresh(trip)

    return {"message": "Voyage créé", "trip_id": trip.trip_id, "banner_url": banner_url}


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

    # Historique
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

    if trip_title is not None: trip.trip_title = trip_title
    if trip_description is not None: trip.trip_description = trip_description
    if start_date is not None: trip.start_date = start_date
    if end_date is not None: trip.end_date = end_date
    if is_public is not None: trip.is_public_flag = "Y" if is_public else "N"

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


# ============================================================
# 11. LISTER LES POSTS (SOUVENIRS) D'UN VOYAGE
# ============================================================
@router.get("/trips/{trip_id}/posts")
def get_trip_posts(
    trip_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    # 1. Vérification d'accès
    trip = db.query(models.Trip).filter_by(trip_id=trip_id).first()

    if not trip:
        raise HTTPException(404, "Voyage introuvable")

    if trip.is_public_flag == "N" and trip.user_id != current_user.user_id:
        raise HTTPException(403, "Voyage privé")

    # 2. Requête SQL complète (Style Feed)
    # C'est ce qui manquait : récupération du user, des likes, des commentaires et des images.
    sql = text("""
        SELECT 
            p.*, 
            u.username, 
            u.profile_picture,
            
            -- Récupération des médias concaténés
            (SELECT GROUP_CONCAT(media_url SEPARATOR ',') FROM media m WHERE m.post_id = p.post_id) as media_urls,
            
            -- Compteurs et Status pour l'utilisateur connecté (:me)
            (SELECT COUNT(*) FROM likes l WHERE l.post_id = p.post_id) as likes_count,
            (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.post_id) as comments_count,
            (SELECT COUNT(*) FROM likes l WHERE l.post_id = p.post_id AND l.user_id = :me) as is_liked

        FROM posts p
        JOIN users u ON u.user_id = p.user_id
        WHERE p.trip_id = :tid
        ORDER BY p.creation_date ASC
    """)

    # Exécution de la requête avec les paramètres
    res = db.execute(sql, {"tid": trip_id, "me": current_user.user_id}).mappings().all()

    return list(res)


# ============================================================
# 12. RÉCUPÉRER LES VOYAGES D'UN UTILISATEUR SPÉCIFIQUE
# ============================================================
@router.get("/trips/user/{target_user_id}")
def get_trips_by_user(
    target_user_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    query = db.query(models.Trip).filter(models.Trip.user_id == target_user_id)

    if current_user.user_id != target_user_id:
        query = query.filter(models.Trip.is_public_flag == "Y")

    trips = query.all()
    return trips