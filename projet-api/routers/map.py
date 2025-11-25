# routers/map.py
from sqlalchemy import text
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
import models
from .auth import get_current_user

router = APIRouter(tags=["Map"])



def refresh_map_feed(db: Session):
    # On vide la table
    db.execute(text("TRUNCATE TABLE map_feed"))

    # On la remplit à partir des autres tables
    sql = text("""
        INSERT INTO map_feed (
            post_id,
            user_id,
            username,
            profile_picture,
            latitude,
            longitude,
            post_title,
            post_description,
            publication_date,
            preview_image,
            place_name,
            city_name,
            country_code,
            likes_count
        )
        SELECT 
            p.post_id,
            p.user_id,
            u.username,
            u.profile_picture,
            p.latitude,
            p.longitude,
            p.post_title,
            p.post_description,
            p.publication_date,
            m.thumbnail_url AS preview_image,
            pl.place_name,
            c.city_name,
            co.country_code,
            (SELECT COUNT(*) FROM likes l WHERE l.post_id = p.post_id) AS likes_count
        FROM posts p
        INNER JOIN users u ON p.user_id = u.user_id
        LEFT JOIN user_preferences up ON u.user_id = up.user_id
        LEFT JOIN media m ON p.post_id = m.post_id 
            AND m.media_id = (SELECT MIN(media_id) FROM media WHERE post_id = p.post_id)
        LEFT JOIN places pl ON p.place_id = pl.place_id
        LEFT JOIN cities c ON pl.city_id = c.city_id
        LEFT JOIN countries co ON c.country_id = co.country_id
        WHERE p.latitude IS NOT NULL 
          AND p.longitude IS NOT NULL
          AND p.privacy = 'PUBLIC'
          AND (up.show_on_map IS NULL OR up.show_on_map = 1)
          AND u.is_active_flag = 'Y'
        ORDER BY p.publication_date DESC;
    """)
    db.execute(sql)
    db.commit()


@router.post("/admin/map/refresh")
def refresh_map(
    db: Session = Depends(get_db),
    _current_user: models.User = Depends(get_current_user),
):
    # si un jour tu as un flag is_admin sur User,
    # tu pourras vérifier ici
    refresh_map_feed(db)
    return {"message": "map_feed rafraîchie"}

@router.get("/map/posts")
def get_posts_on_map(
    min_lat: float,
    max_lat: float,
    min_lng: float,
    max_lng: float,
    scope: str = "friends",  # "me", "friends", "all"
    db: Session = Depends(get_db),
    _current_user: models.User = Depends(get_current_user),
):
    """
    Récupère les posts dans une zone (bounding box).
    Il faudra adapter les filtres selon ta BDD (visibilité, amis, etc.).
    """
    q = db.query(models.Post).filter(
        models.Post.latitude >= min_lat,
        models.Post.latitude <= max_lat,
        models.Post.longitude >= min_lng,
        models.Post.longitude <= max_lng,
    )

    # TODO: ajouter des filtres selon 'scope' et relations d'amis

    return q.all()
