# routers/stories.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from sqlalchemy import text

import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Stories"])


@router.post("/stories/{story_id}/view")
def view_story(
    story_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    story = db.query(models.Story).filter_by(story_id=story_id).first()
    if not story:
        raise HTTPException(404, "Story introuvable")

    # Vérifier si déjà vue
    existing = db.query(models.StoryView).filter_by(
        story_id=story_id,
        user_id=current_user.user_id
    ).first()

    if existing:
        # on met éventuellement à jour la date
        existing.viewed_at = datetime.now(timezone.utc)
    else:
        sv = models.StoryView(
            story_id=story_id,
            user_id=current_user.user_id,
            viewed_at=datetime.now(timezone.utc),
        )
        db.add(sv)

    # +1 au compteur (option simple, tu peux aussi le recalculer avec COUNT)
    story.view_count = (story.view_count or 0) + 1

    db.commit()
    return {"message": "Story vue"}


@router.get("/stories/{story_id}/views")
def list_story_views(
    story_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    story = db.query(models.Story).filter_by(story_id=story_id).first()
    if not story:
        raise HTTPException(404, "Story introuvable")

    # Optionnel : vérifier que current_user a le droit de voir qui a vu (ex: owner)
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
