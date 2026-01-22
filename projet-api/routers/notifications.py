# routers/notifications.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime, timezone

import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Notifications"])


# 🔧 Helper réutilisable partout
def create_notification(
    db: Session,
    target_user_id: int,
    notif_type: str,
    notif_text: str,
    related_id: int | None = None,
    related_table: str | None = None,
    creator_id: int | None = None,
):
    """
    Crée une notification simple.
    """
    notif = models.Notification(
        user_id=target_user_id,
        notification_text=notif_text,
        notification_type=notif_type,
        related_id=related_id,
        related_table=related_table,
        creation_date=datetime.now(timezone.utc),
        created_by=creator_id,
        last_modification_date=datetime.now(timezone.utc),
        last_modified_by=creator_id,
    )
    db.add(notif)
    db.commit()
    return notif



# ============================================================
# 📨 GET — Toutes mes notifications
# ============================================================
@router.get("/notifications")
def get_my_notifications(
    unread_only: bool = False,
    limit: int = 50,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    q = db.query(models.Notification).filter(
        models.Notification.user_id == current_user.user_id
    )

    if unread_only:
        q = q.filter(models.Notification.is_read_flag == "N")

    notifications = (
        q.order_by(desc(models.Notification.creation_date))
        .limit(limit)
        .all()
    )

    return notifications


# ============================================================
# 🔔 Marquer une notification comme lue
# ============================================================
@router.post("/notifications/{notification_id}/read")
def mark_as_read(
    notification_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    notif = db.query(models.Notification).filter_by(
        notification_id=notification_id
    ).first()

    if not notif:
        raise HTTPException(status_code=404, detail="Notification introuvable")

    if notif.user_id != current_user.user_id:
        raise HTTPException(status_code=403, detail="Accès interdit")

    notif.is_read_flag = "Y"
    notif.last_modified_by = current_user.user_id

    db.commit()
    return {"message": "Notification marquée comme lue"}


# ============================================================
# 🔄 Tout marquer comme lu
# ============================================================
@router.post("/notifications/read-all")
def mark_all_as_read(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    db.query(models.Notification).filter(
        models.Notification.user_id == current_user.user_id,
        models.Notification.is_read_flag == "N"
    ).update({"is_read_flag": "Y"})

    db.commit()
    return {"message": "Toutes les notifications marquées comme lues"}


# ============================================================
# ❌ Supprimer une notification
# ============================================================
@router.delete("/notifications/{notification_id}")
def delete_notification(
    notification_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    notif = db.query(models.Notification).filter_by(
        notification_id=notification_id
    ).first()

    if not notif:
        raise HTTPException(404, "Notification introuvable")

    if notif.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux supprimer QUE tes notifications")

    db.delete(notif)
    db.commit()

    return {"message": "Notification supprimée"}
