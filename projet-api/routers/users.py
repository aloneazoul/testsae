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
def me(current_user: models.User = Depends(get_current_user)):
    """
    Retourne les infos de l'utilisateur connecté.
    """
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



@router.get("/me")
def me(current_user: models.User = Depends(get_current_user)):
    """
    Retourne les infos de l'utilisateur connecté.
    """
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
    }