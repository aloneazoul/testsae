from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone, timedelta
import cloudinary
import cloudinary.uploader

import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Stories"])

# ============================================================
# 1. CRÉER UNE STORY
# ============================================================
@router.post("/stories")
def create_story(
    file: UploadFile = File(...),
    caption: str = Form(None),
    latitude: str = Form(None),
    longitude: str = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    try:
        upload = cloudinary.uploader.upload(
            file.file,
            folder=f"stories/{current_user.user_id}/",
            resource_type="auto"
        )
    except Exception as e:
        raise HTTPException(500, f"Erreur Cloudinary: {e}")

    media_type = "IMAGE"
    if upload.get("resource_type") == "video":
        media_type = "VIDEO"

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(hours=24)

    story = models.Story(
        user_id=current_user.user_id,
        media_url=upload["secure_url"],
        thumbnail_url=upload.get("thumbnail_url"),
        media_type=media_type,
        caption=caption,
        latitude=latitude,
        longitude=longitude,
        created_at=now,
        expires_at=expires_at,
        view_count=0
    )

    db.add(story)
    db.commit()
    db.refresh(story)

    return {"message": "Story publiée", "story_id": story.story_id, "url": story.media_url}


# ============================================================
# 2. FEED DES STORIES (CORRIGÉ)
# ============================================================
@router.get("/stories/feed")
def get_stories_feed(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc)

    # Récupérer les stories actives : de soi-même, des amis, ET des abonnements
    sql = text("""
        SELECT 
            s.story_id, s.media_url, s.media_type, s.created_at, s.caption, s.latitude, s.longitude,
            u.user_id, u.username, u.profile_picture,
            CASE WHEN sv.viewed_at IS NOT NULL THEN 1 ELSE 0 END as is_viewed
        FROM stories s
        JOIN users u ON u.user_id = s.user_id
        LEFT JOIN story_views sv ON s.story_id = sv.story_id AND sv.user_id = :me
        WHERE s.expires_at > :now
        AND (
            s.user_id = :me
            OR s.user_id IN (
                -- Mes amis
                SELECT CASE WHEN f.user_id = :me THEN f.user_id_friend ELSE f.user_id END
                FROM friends f
                WHERE f.status = 'ACCEPTED' AND (f.user_id = :me OR f.user_id_friend = :me)
            )
            OR s.user_id IN (
                -- Les personnes que je suis (abonnements)
                SELECT user_id 
                FROM followers 
                WHERE follower_user_id = :me AND status = 'ACCEPTED'
            )
        )
        ORDER BY s.created_at ASC
    """)

    rows = db.execute(sql, {"me": current_user.user_id, "now": now}).mappings().all()

    grouped_stories = {}

    for row in rows:
        uid = row["user_id"]
        is_mine = (uid == current_user.user_id)

        if uid not in grouped_stories:
            grouped_stories[uid] = {
                "user_id": uid,
                "username": row["username"],
                "profile_picture": row["profile_picture"],
                "is_mine": is_mine,
                "all_seen": True, # Par défaut True, passe à False si une story non vue est trouvée
                "stories": []
            }

        story_data = {
            "story_id": row["story_id"],
            "media_url": row["media_url"],
            "media_type": row["media_type"],
            "date": row["created_at"],
            "caption": row["caption"],
            "latitude": row["latitude"],
            "longitude": row["longitude"],
            "is_viewed": bool(row["is_viewed"])
        }
        
        # Si une story n'est pas vue (et ce n'est pas la mienne), le groupe n'est pas "tout vu"
        if not story_data["is_viewed"] and not is_mine:
            grouped_stories[uid]["all_seen"] = False

        grouped_stories[uid]["stories"].append(story_data)

    result = list(grouped_stories.values())
    
    # Tri : Moi d'abord, puis ceux qui ont des nouvelles stories (all_seen=False), puis le reste
    result.sort(key=lambda x: (not x['is_mine'], x['all_seen'])) 

    return result


# ============================================================
# 3. MARQUER COMME VUE
# ============================================================
@router.post("/stories/{story_id}/view")
def view_story(
    story_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    story = db.query(models.Story).filter_by(story_id=story_id).first()
    if not story:
        raise HTTPException(404, "Story introuvable")

    existing = db.query(models.StoryView).filter_by(
        story_id=story_id,
        user_id=current_user.user_id
    ).first()

    if not existing:
        sv = models.StoryView(
            story_id=story_id,
            user_id=current_user.user_id,
            viewed_at=datetime.now(timezone.utc),
        )
        db.add(sv)
        story.view_count = (story.view_count or 0) + 1
        db.commit()

    return {"message": "Story vue"}


# ============================================================
# 4. LISTE DES VUES (Pour mes stories)
# ============================================================
@router.get("/stories/{story_id}/views")
def list_story_views(
    story_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    story = db.query(models.Story).filter_by(story_id=story_id).first()
    if not story:
        raise HTTPException(404, "Story introuvable")

    if story.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux voir les vues que de tes stories")

    sql = text("""
        SELECT u.user_id, u.username, u.profile_picture, sv.viewed_at
        FROM story_views sv
        JOIN users u ON u.user_id = sv.user_id
        WHERE sv.story_id = :sid
        ORDER BY sv.viewed_at DESC;
    """)
    res = db.execute(sql, {"sid": story_id}).mappings().all()
    return list(res)


# ============================================================
# 5. SUPPRIMER UNE STORY
# ============================================================
@router.delete("/stories/{story_id}")
def delete_story(
    story_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    story = db.query(models.Story).filter(models.Story.story_id == story_id).first()
    
    if not story:
        raise HTTPException(404, "Story introuvable")
        
    if story.user_id != current_user.user_id:
        raise HTTPException(403, "Vous ne pouvez supprimer que vos propres stories")

    db.delete(story)
    db.commit()

    return {"message": "Story supprimée"}


# ============================================================
# 6. RÉCUPÉRER LES STORIES D'UN UTILISATEUR (Profil)
# ============================================================
@router.get("/stories/user/{target_user_id}")
def get_user_stories(
    target_user_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc)
    sql = text("""
        SELECT 
            s.story_id, s.media_url, s.media_type, s.created_at, s.caption, s.latitude, s.longitude,
            CASE WHEN sv.viewed_at IS NOT NULL THEN 1 ELSE 0 END as is_viewed
        FROM stories s
        LEFT JOIN story_views sv ON s.story_id = sv.story_id AND sv.user_id = :me
        WHERE s.user_id = :target
        AND s.expires_at > :now
        ORDER BY s.created_at ASC
    """)

    rows = db.execute(sql, {"me": current_user.user_id, "target": target_user_id, "now": now}).mappings().all()

    stories = []
    all_seen = True

    for row in rows:
        is_viewed = bool(row["is_viewed"])
        if not is_viewed:
            all_seen = False
            
        stories.append({
            "story_id": row["story_id"],
            "media_url": row["media_url"],
            "media_type": row["media_type"],
            "date": row["created_at"],
            "caption": row["caption"],
            "latitude": row["latitude"],
            "longitude": row["longitude"],
            "is_viewed": is_viewed
        })

    return {
        "user_id": target_user_id,
        "all_seen": all_seen,
        "stories": stories
    }