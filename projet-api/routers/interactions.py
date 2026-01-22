# routers/interactions.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from sqlalchemy import text, desc

import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Interactions"])


VALID_INTERACTIONS = ["VIEW", "LIKE", "SHARE", "SAVE", "COMMENT", "SKIP"]


# ============================================================
# 1. LOGGER UNE INTERACTION
# ============================================================
@router.post("/interactions")
def log_interaction(
    post_id: int,
    interaction_type: str,
    duration_seconds: int | None = None,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    if interaction_type not in VALID_INTERACTIONS:
        raise HTTPException(status_code=400, detail="Type d'interaction invalide")

    post = db.query(models.Post).filter_by(post_id=post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post introuvable")

    interaction = models.UserInteraction(
        user_id=current_user.user_id,
        post_id=post_id,
        interaction_type=interaction_type,
        duration_seconds=duration_seconds,
        interaction_date=datetime.now(timezone.utc),
    )
    db.add(interaction)
    db.commit()

    return {"message": "Interaction enregistrée"}


# ============================================================
# 2. VOIR MES DERNIÈRES INTERACTIONS
# ============================================================
@router.get("/interactions/me")
def my_interactions(
    interaction_type: str | None = None,
    limit: int = 50,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    q = db.query(models.UserInteraction).filter(
        models.UserInteraction.user_id == current_user.user_id
    )

    if interaction_type:
        if interaction_type not in VALID_INTERACTIONS:
            raise HTTPException(status_code=400, detail="Type d'interaction invalide")
        q = q.filter(models.UserInteraction.interaction_type == interaction_type)

    interactions = (
        q.order_by(desc(models.UserInteraction.interaction_date))
        .limit(limit)
        .all()
    )

    return interactions


# ============================================================
# 3. STAT INTERACTIONS SUR UN POST
# ============================================================
@router.get("/interactions/post/{post_id}")
def post_interactions_stats(
    post_id: int,
    db: Session = Depends(database.get_db),
):
    sql = text("""
        SELECT interaction_type, COUNT(*) AS count
        FROM user_interactions
        WHERE post_id = :pid
        GROUP BY interaction_type;
    """)
    res = db.execute(sql, {"pid": post_id}).mappings().all()
    return list(res)
