# routers/posts.py

from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import text, desc
from datetime import datetime, timezone
import cloudinary
import cloudinary.uploader
import database
import models
from .auth import get_current_user
from .notifications import create_notification
from routers.map import refresh_map_feed

router = APIRouter(tags=["Posts"])


# ============================================================
# 1. CRÉER UN POST
# ============================================================
@router.post("/posts")
def create_post(
    post_title: str = Form(None),
    post_description: str = Form(None),
    privacy: str = Form("PUBLIC"),
    allow_comments: bool = Form(True),
    latitude: float = Form(None),
    longitude: float = Form(None),
    trip_id: int = Form(None),
    place_id: int = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    if privacy not in ["PUBLIC", "FRIENDS", "PRIVATE"]:
        raise HTTPException(400, "Privacy invalide")

    post = models.Post(
        post_title=post_title,
        post_description=post_description,
        privacy=privacy,
        allow_comments_flag="Y" if allow_comments else "N",
        latitude=latitude,
        longitude=longitude,
        trip_id=trip_id,
        place_id=place_id,
        user_id=current_user.user_id,
        created_by=current_user.user_id,
        last_modified_by=current_user.user_id,
        last_modification_date=datetime.now(timezone.utc),
    )

    db.add(post)
    db.commit()
    db.refresh(post)

    # ensuite seulement, quand le post existe bien en BDD
    refresh_map_feed(db)

    return {"message": "Post créé", "post_id": post.post_id}


# ============================================================
# 2. UPLOAD MEDIA DANS UN POST
# ============================================================
@router.post("/posts/{post_id}/media")
def upload_media(
    post_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()

    if not post:
        raise HTTPException(404, "Post introuvable")
    if post.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux modifier que tes posts")

    try:
        upload = cloudinary.uploader.upload(
            file.file,
            folder=f"posts/{post_id}/",
            resource_type="auto"
        )
    except Exception as e:
        raise HTTPException(500, f"Erreur Cloudinary: {e}")

    media_type = "IMAGE" if upload.get("resource_type") == "image" else "VIDEO"

    media = models.Media(
        post_id=post_id,
        media_url=upload["secure_url"],
        thumbnail_url=upload.get("thumbnail_url"),
        media_type=media_type,
        cloud_id=upload.get("public_id"),
        size=upload.get("bytes"),
        width=upload.get("width"),
        height=upload.get("height"),
        duration_seconds=upload.get("duration"),
        original_filename=file.filename,
        created_by=current_user.user_id,
    )

    db.add(media)
    db.commit()

    return {"message": "Media ajouté", "url": upload["secure_url"]}


# ============================================================
# 3. FEED (posts que je peux voir)
# ============================================================
@router.get("/posts/feed")
def get_feed(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    sql = text("""
        SELECT p.*, u.username, u.profile_picture
        FROM posts p
        JOIN users u ON u.user_id = p.user_id
        WHERE 
            p.privacy = 'PUBLIC'
            OR (p.privacy = 'FRIENDS' AND p.user_id IN (
                SELECT 
                    CASE 
                        WHEN f.user_id = :me THEN f.user_id_friend
                        ELSE f.user_id
                    END
                FROM friends f
                WHERE f.status = 'ACCEPTED'
                AND (f.user_id = :me OR f.user_id_friend = :me)
            ))
            OR p.user_id = :me
        ORDER BY publication_date DESC
        LIMIT 100
    """)

    res = db.execute(sql, {"me": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 4. RECHERCHE DE POSTS (full text)
# ============================================================
@router.get("/posts/search")
def search_posts(query: str, db: Session = Depends(database.get_db)):
    sql = text("""
        SELECT p.post_id, p.post_title, p.post_description, u.username
        FROM posts p
        JOIN users u ON u.user_id = p.user_id
        WHERE MATCH(p.post_title, p.post_description) AGAINST (:q IN BOOLEAN MODE)
        ORDER BY publication_date DESC
        LIMIT 50;
    """)


    res = db.execute(sql, {"q": query}).mappings().all()
    return list(res)


# ============================================================
# 5. SUPPRIMER UN POST
# ============================================================
@router.delete("/posts/{post_id}")
def delete_post(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()
    if not post:
        raise HTTPException(404, "Post introuvable")
    if post.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux supprimer que tes posts")

    db.delete(post)
    db.commit()

    return {"message": "Post supprimé"}


# ============================================================
# 6. POSTS SUR LA MAP
# ============================================================
@router.get("/posts/map")
def posts_on_map(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    sql = text("""
        SELECT p.post_id, p.latitude, p.longitude, u.username
        FROM posts p
        JOIN users u ON u.user_id = p.user_id
        WHERE p.latitude IS NOT NULL AND p.longitude IS NOT NULL
        AND (
            p.privacy = 'PUBLIC'
            OR p.user_id = :me
        )
    """)
    res = db.execute(sql, {"me": current_user.user_id}).mappings().all()
    return list(res)



@router.post("/posts/{post_id}/like")
def like_post(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()
    if not post:
        raise HTTPException(404, "Post introuvable")

    existing = db.query(models.Like).filter_by(
        post_id=post_id,
        user_id=current_user.user_id
    ).first()

    if existing:
        return {"message": "Déjà liké"}

    like = models.Like(
        post_id=post_id,
        user_id=current_user.user_id,
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
        last_modification_date=datetime.now(timezone.utc),
        last_modified_by=current_user.user_id,
    )
    db.add(like)
    db.commit()
    if post.user_id != current_user.user_id:
        create_notification(
            db=db,
            target_user_id=post.user_id,
            notif_type="LIKE",
            notif_text=f"{current_user.username} a aimé votre post",
            related_id=post.post_id,
            related_table="posts",
            creator_id=current_user.user_id,
        )
    return {"message": "Like ajouté"}


@router.delete("/posts/{post_id}/like")
def unlike_post(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    like = db.query(models.Like).filter_by(
        post_id=post_id,
        user_id=current_user.user_id
    ).first()

    if not like:
        raise HTTPException(404, "Tu n'as pas liké ce post")

    db.delete(like)
    db.commit()

    return {"message": "Like retiré"}


@router.get("/posts/{post_id}/likes")
def get_post_likes(
    post_id: int,
    db: Session = Depends(database.get_db),
):
    sql = text("""
        SELECT u.user_id, u.username, u.profile_picture
        FROM likes l
        JOIN users u ON u.user_id = l.user_id
        WHERE l.post_id = :pid
    """)
    res = db.execute(sql, {"pid": post_id}).mappings().all()
    return list(res)


@router.post("/posts/{post_id}/save")
def save_post(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()
    if not post:
        raise HTTPException(404, "Post introuvable")

    existing = db.query(models.SavedPost).filter_by(
        post_id=post_id,
        user_id=current_user.user_id
    ).first()

    if existing:
        return {"message": "Déjà dans les favoris"}

    saved = models.SavedPost(
        post_id=post_id,
        user_id=current_user.user_id,
        saved_at=datetime.now(timezone.utc),
    )
    db.add(saved)
    db.commit()

    return {"message": "Post ajouté aux favoris"}


@router.delete("/posts/{post_id}/save")
def unsave_post(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    saved = db.query(models.SavedPost).filter_by(
        post_id=post_id,
        user_id=current_user.user_id
    ).first()

    if not saved:
        raise HTTPException(404, "Ce post n'est pas dans tes favoris")

    db.delete(saved)
    db.commit()

    return {"message": "Post retiré des favoris"}


@router.post("/posts/{post_id}/share")
def share_post(
    post_id: int,
    share_type: str = Form(...),  # DIRECT_MESSAGE / STORY / REPOST
    receiver_id: int = Form(...),
    message: str = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    valid_types = ["DIRECT_MESSAGE", "STORY", "REPOST"]
    if share_type not in valid_types:
        raise HTTPException(400, "Type de partage invalide")

    post = db.query(models.Post).filter_by(post_id=post_id).first()
    if not post:
        raise HTTPException(404, "Post introuvable")

    receiver = db.query(models.User).filter_by(user_id=receiver_id).first()
    if not receiver:
        raise HTTPException(404, "Utilisateur destinataire introuvable")

    share = models.PostShare(
        post_id=post_id,
        sender_id=current_user.user_id,
        receiver_id=receiver_id,
        share_type=share_type,
        message=message,
        shared_at=datetime.now(timezone.utc),
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
    )
    db.add(share)
    db.commit()
    # 🔔 notif au destinataire du partage (DM / story / repost)
    if receiver_id != current_user.user_id:
        create_notification(
            db=db,
            target_user_id=receiver_id,
            notif_type="SHARED_POST",
            notif_text=f"{current_user.username} t'a partagé un post",
            related_id=post_id,
            related_table="posts",
            creator_id=current_user.user_id,
        )

    # 🔔 notif au propriétaire du post si c'est un REPOST public, par exemple
    if share_type == "REPOST" and post.user_id not in (None, current_user.user_id, receiver_id):
        create_notification(
            db=db,
            target_user_id=post.user_id,
            notif_type="SHARED_POST",
            notif_text=f"{current_user.username} a repartagé votre post",
            related_id=post_id,
            related_table="posts",
            creator_id=current_user.user_id,
        )
    return {"message": "Post partagé"}


# ============================================================
# 7. RÉCUPÉRER LES MÉDIAS D'UN POST
# ============================================================
@router.get("/posts/{post_id}/media")
def get_post_media(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()

    if not post:
        raise HTTPException(404, 'Post introuvable')
    
    # Correction de 'user_ud' -> 'user_id'
    if post.privacy == 'PRIVATE' and post.user_id != current_user.user_id:
        raise HTTPException(403, "Post privé")
    
    # On trie par rang dans le carrousel
    res = db.query(models.Media)\
            .filter_by(post_id=post_id)\
            .order_by(models.Media.carrousel_rank)\
            .all()
            
    return list(res)


# ============================================================
# 8. RÉCUPÉRER LE PREMIER MÉDIAS D'UN POST
# ============================================================
@router.get("/posts/{post_id}/media/first")
def get_post_first_media(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()

    if not post:
        raise HTTPException(404, 'Post introuvable')
    
    # Correction de 'user_ud' -> 'user_id'
    if post.privacy == 'PRIVATE' and post.user_id != current_user.user_id:
        raise HTTPException(403, "Post privé")
    
    # On trie par rang dans le carrousel
    res = db.query(models.Media)\
            .filter_by(post_id=post_id)\
            .order_by(models.Media.carrousel_rank)\
            .first()
            
    if not res:
        return None
    else:
        return {
            "media_id": res.media_id,
            "media_url": res.media_url,
            "post_id": res.post_id
        }


# ============================================================
# 9. RÉCUPÉRER TOUS LES POSTS
# ============================================================
@router.get("/posts")
def get_post(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    res = db.query(models.Post).filter_by(user_id=current_user.user_id).order_by(desc(models.Post.creation_date)).all()
            
    if not res:
        return None
    else:
        return list(res)