# routers/users.py

from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone, date
import cloudinary
import cloudinary.uploader
import os
import database
from database import get_db
import models
from .auth import get_current_user

router = APIRouter(tags=["Users"])

# Config Cloudinary (tu peux aussi le mettre ailleurs et l'importer)
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "dio0m73b8"),
    api_key=os.getenv("CLOUDINARY_API_KEY", "176583934591119"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET", "EwbWKNCXrzvYNVNGEG72c0nfBF0"),
)

@router.get("/me")
def me(
    db: Session = Depends(get_db),  # <--- Important : on a besoin de la DB ici
    current_user: models.User = Depends(get_current_user)
):
    # 👇 CES LIGNES SONT INDISPENSABLES POUR LE CALCUL
    followers_count = db.query(models.Follower).filter_by(user_id=current_user.user_id, status="ACCEPTED").count()
    following_count = db.query(models.Follower).filter_by(follower_user_id=current_user.user_id, status="ACCEPTED").count()
    posts_count = db.query(models.Post).filter_by(user_id=current_user.user_id).count()
    # 👆 FIN DU CALCUL

    return {
        "id": current_user.user_id,
        "email": current_user.email,
        "pseudo": current_user.username,
        "gender": current_user.gender,
        "bio": current_user.bio,
        "phone": current_user.phone_number,
        "birth_date": current_user.birth_date,
        "is_private": current_user.is_private_flag == "Y",
        "img": current_user.profile_picture,
        
        # On injecte les variables calculées au-dessus
        "followers_count": followers_count,
        "following_count": following_count,
        "posts_count": posts_count,
    }

@router.post("/me/avatar")
def upload_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Upload / met à jour la photo de profil sur Cloudinary.
    """
    try:
        upload_result = cloudinary.uploader.upload(
            file.file,
            folder=f"user_{current_user.user_id}/profile/",
            unique_filename=True,
            overwrite=True,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur upload Cloudinary : {e}")

    current_user.profile_picture = upload_result["secure_url"]
    db.commit()
    db.refresh(current_user)

    return {"message": "Image uploadée ✅", "url": current_user.profile_picture}


@router.put("/me")
def update_profile(
    gender: str = Form(None),
    bio: str = Form(None),
    phone: str = Form(None),
    birth_date: date = Form(None),
    is_private: bool = Form(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if gender is not None:
        current_user.gender = gender

    if bio is not None:
        current_user.bio = bio

    if phone is not None:
        current_user.phone_number = phone

    if birth_date is not None:
        current_user.birth_date = birth_date

    if is_private is not None:
        current_user.is_private_flag = "Y" if is_private else "N"

    current_user.last_modified_by = current_user.user_id
    current_user.last_modification_date = datetime.now(timezone.utc)
    db.commit()
    db.refresh(current_user)

    return {"message": "Profil mis à jour"}


@router.get("/me/preferences")
def get_preferences(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    prefs = (
        db.query(models.UserPreferences)
        .filter(models.UserPreferences.user_id == current_user.user_id)
        .first()
    )

    return {
        "theme": prefs.theme,
        "language": prefs.language,
        "notifications_enabled": prefs.notifications_enabled,
        "location_sharing_enabled": prefs.location_sharing_enabled,
        "show_on_map": prefs.show_on_map,
    }


@router.put("/me/preferences")
def update_preferences(
    theme: str = Form(None),
    language: str = Form(None),
    notifications_enabled: bool = Form(None),
    location_sharing_enabled: bool = Form(None),
    show_on_map: bool = Form(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    prefs = (
        db.query(models.UserPreferences)
        .filter(models.UserPreferences.user_id == current_user.user_id)
        .first()
    )
    valid_themes = ["LIGHT", "DARK", "AUTO"]

    if theme is not None:
        if theme not in valid_themes:
            raise HTTPException(status_code=400, detail="Thème invalide")
        prefs.theme = theme

    if language is not None:
        prefs.language = language

    if notifications_enabled is not None:
        prefs.notifications_enabled = notifications_enabled

    if location_sharing_enabled is not None:
        prefs.location_sharing_enabled = location_sharing_enabled

    if show_on_map is not None:
        prefs.show_on_map = show_on_map

    prefs.last_modification_date = datetime.now(timezone.utc)


    db.commit()
    db.refresh(prefs)

    return {"message": "Préférences mises à jour"}


@router.get("/me/saved-posts")
def get_my_saved_posts(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    sql = text("""
        SELECT p.post_id, p.post_title, p.post_description, p.publication_date,
               u.user_id, u.username, u.profile_picture
        FROM saved_posts s
        JOIN posts p ON p.post_id = s.post_id
        JOIN users u ON u.user_id = p.user_id
        WHERE s.user_id = :uid
        ORDER BY s.saved_at DESC;
    """)
    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 6. RÉCUPÉRER UN UTILISATEUR PAR SON ID (PUBLIC)
# ============================================================
@router.get("/users/{user_id}")
def get_user_by_id(
    user_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    user = db.query(models.User).filter(models.User.user_id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    # Relations
    is_following = False
    rel_me_to_him = db.query(models.Follower).filter_by(
        user_id=user_id,
        follower_user_id=current_user.user_id,
        status="ACCEPTED"
    ).first()
    if rel_me_to_him:
        is_following = True

    follows_me = False
    rel_him_to_me = db.query(models.Follower).filter_by(
        user_id=current_user.user_id,
        follower_user_id=user_id,
        status="ACCEPTED"
    ).first()
    if rel_him_to_me:
        follows_me = True

    # Stats pour l'utilisateur visité
    followers_count = db.query(models.Follower).filter_by(user_id=user_id, status="ACCEPTED").count()
    following_count = db.query(models.Follower).filter_by(follower_user_id=user_id, status="ACCEPTED").count()
    posts_count = db.query(models.Post).filter_by(user_id=user_id).count()

    return {
        "id": user.user_id,
        "pseudo": user.username,
        "bio": user.bio,
        "img": user.profile_picture,
        "is_private": user.is_private_flag == "Y",
        "is_following": is_following,
        "follows_me": follows_me,
        "followers_count": followers_count,
        "following_count": following_count,
        "posts_count": posts_count,
    }

# ============================================================
# 7. RECHERCHE UTILISATEURS AVEC STATUT PRÉCIS
# ============================================================
@router.get("/search/users")
def search_users(
    query: str = "",
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    # Récupération des utilisateurs (50 max)
    if not query or query.strip() == "":
        users = db.query(models.User).filter(
            models.User.user_id != current_user.user_id
        ).limit(50).all()
    else:
        users = db.query(models.User).filter(
            models.User.username.ilike(f"%{query}%"),
            models.User.user_id != current_user.user_id
        ).limit(50).all()

    results = []
    for u in users:
        status_text = ""

        # 1. Est-ce que JE le suis ?
        i_follow_him = db.query(models.Follower).filter_by(
            user_id=u.user_id,                  # Cible = Lui
            follower_user_id=current_user.user_id, # Follower = Moi
            status="ACCEPTED"
        ).first()

        # 2. Est-ce qu'IL me suit ?
        he_follows_me = db.query(models.Follower).filter_by(
            user_id=current_user.user_id,       # Cible = Moi
            follower_user_id=u.user_id,         # Follower = Lui
            status="ACCEPTED"
        ).first()

        # --- LOGIQUE DES STATUTS ---
        if i_follow_him and he_follows_me:
            status_text = "ami(e)s"     # Mutuel
        elif i_follow_him:
            status_text = "Suivi"       # Je le suis (mais pas lui)
        elif he_follows_me:
            status_text = "vous suit"   # Il me suit (mais pas moi)
        
        # Sinon "" (Rien)

        results.append({
            "user_id": u.user_id,
            "username": u.username,
            "profile_picture": u.profile_picture,
            "status": status_text
        })

    return results