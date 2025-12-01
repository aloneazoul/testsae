# routers/friends.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime
from database import get_db
import models
from .auth import get_current_user
from .notifications import create_notification

router = APIRouter(tags=["Friends"])



# ============================================================
# 🔍 1. RECHERCHER UN UTILISATEUR PAR TEXTE
# ============================================================
@router.get("/search/users")
def search_users(
    query: str = "",
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    
    sql = ""
    params = {}
    

    """
    Recherche full-text via l'index GIN (username).
    """
    # EN postgresql
    #sql = text("""
    #    SELECT user_id, username, profile_picture
    #""    FROM users
    #    WHERE to_tsvector('french', username) @@ plainto_tsquery('french', :q)
    #    LIMIT 20;
    #""")

    if query and query.strip():
        sql = text("""
            SELECT user_id, username, profile_picture
            FROM users
            WHERE username LIKE :q 
            AND user_id != :uid
            LIMIT 20;
        """)
        params = {"q": f"%{query}%", "uid": current_user.user_id}

    else:
        sql = text("""
            SELECT user_id, username, profile_picture
            FROM users
            WHERE user_id != :uid
            ORDER BY creation_date DESC
            LIMIT 50;
        """)
        params = {"uid": current_user.user_id}

    res = db.execute(sql, params).mappings().all()

    return list(res)


# ============================================================
# 2. ENVOYER UNE DEMANDE D’AMI
# ============================================================
@router.post("/friends/requests")
def send_friend_request(
    target_user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if target_user_id == current_user.user_id:
        raise HTTPException(400, "Tu ne peux pas t'ajouter toi-même")

    # Vérifier si user existe
    target = db.query(models.User).filter_by(user_id=target_user_id).first()
    if not target:
        raise HTTPException(404, "Utilisateur introuvable")

    # Vérifier si relation existe déjà
    existing = db.query(models.Friend).filter_by(
        user_id=current_user.user_id,
        user_id_friend=target_user_id
    ).first()

    if existing:
        raise HTTPException(400, "Une relation existe déjà")

    # Création de la demande
    fr = models.Friend(
        user_id=current_user.user_id,
        user_id_friend=target_user_id,
        status="PENDING",
        created_by=current_user.user_id,
    )
    db.add(fr)
    db.commit()

    # Historique
    hist = models.FriendHistory(
        user_id=current_user.user_id,
        user_id_friend=target_user_id,
        status="PENDING",
        changed_by=current_user.user_id
    )
    db.add(hist)
    db.commit()
    # 🔔 notif à la personne ciblée
    if target_user_id != current_user.user_id:
        create_notification(
            db=db,
            target_user_id=target_user_id,
            notif_type="FRIEND_REQUEST",
            notif_text=f"{current_user.username} vous a envoyé une demande d'ami",
            related_id=current_user.user_id,
            related_table="users",
            creator_id=current_user.user_id,
        )
    return {"message": "Demande envoyée"}


# ============================================================
# 3. VOIR MES DEMANDES D’AMIS (reçues ou envoyées)
# ============================================================
@router.get("/friends/requests")
def list_friend_requests(
    type: str = Query("incoming", enum=["incoming", "outgoing"]),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if type == "incoming":
        # Demandes reçues
        sql = text("""
            SELECT f.user_id, u.username, u.profile_picture, f.creation_date
            FROM friends f
            JOIN users u ON u.user_id = f.user_id
            WHERE f.user_id_friend = :uid AND f.status = 'PENDING';
        """)
    else:
        # Demandes envoyées
        sql = text("""
            SELECT f.user_id_friend AS user_id, u.username, u.profile_picture, f.creation_date
            FROM friends f
            JOIN users u ON u.user_id = f.user_id_friend
            WHERE f.user_id = :uid AND f.status = 'PENDING';
        """)

    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 4. ACCEPTER UNE DEMANDE
# ============================================================
@router.post("/friends/requests/{friend_id}/accept")
def accept_friend_request(
    friend_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    fr = db.query(models.Friend).filter_by(
        user_id=friend_id,
        user_id_friend=current_user.user_id,
        status="PENDING"
    ).first()

    if not fr:
        raise HTTPException(404, "Demande introuvable")

    fr.status = "ACCEPTED"
    fr.last_modified_by = current_user.user_id
    fr.last_modification_date = datetime.utcnow()

    # Historique
    hist = models.FriendHistory(
        user_id=friend_id,
        user_id_friend=current_user.user_id,
        status="ACCEPTED",
        changed_by=current_user.user_id
    )
    db.add(hist)

    db.commit()
    # 🔔 notif à celui qui a envoyé la demande
    create_notification(
        db=db,
        target_user_id=friend_id,
        notif_type="FRIEND_REQUEST",
        notif_text=f"{current_user.username} a accepté votre demande d'ami",
        related_id=current_user.user_id,
        related_table="users",
        creator_id=current_user.user_id,
    )
    return {"message": "Demande acceptée"}


# ============================================================
# 5. REJETER / ANNULER UNE DEMANDE
# ============================================================
@router.post("/friends/requests/{friend_id}/reject")
def reject_friend_request(
    friend_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    fr = db.query(models.Friend).filter_by(
        user_id=friend_id,
        user_id_friend=current_user.user_id,
        status="PENDING"
    ).first()

    if not fr:
        raise HTTPException(404, "Demande introuvable")

    fr.status = "REJECTED"
    fr.last_modified_by = current_user.user_id
    fr.last_modification_date = datetime.utcnow()

    hist = models.FriendHistory(
        user_id=friend_id,
        user_id_friend=current_user.user_id,
        status="REJECTED",
        changed_by=current_user.user_id
    )
    db.add(hist)

    db.commit()
    return {"message": "Demande rejetée"}


# ============================================================
# 6. LISTER MES AMIS
# ============================================================
@router.get("/friends")
def list_friends(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    sql = text("""
        SELECT DISTINCT u.user_id, u.username, u.profile_picture
        FROM friends f
        JOIN users u 
        ON (
            (f.user_id = u.user_id AND f.user_id_friend = :uid)
            OR
            (f.user_id_friend = u.user_id AND f.user_id = :uid)
        )
        WHERE f.status = 'ACCEPTED';
    """)

    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 7. RETIRER UN AMI (supprimer la relation)
# ============================================================
@router.delete("/friends/{friend_id}")
def delete_friend(
    friend_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    # Relation dans les deux sens
    fr = db.query(models.Friend).filter(
        text("""
            (user_id = :me AND user_id_friend = :other)
            OR
            (user_id = :other AND user_id_friend = :me)
        """)
    ).params(me=current_user.user_id, other=friend_id).first()

    if not fr:
        raise HTTPException(404, "Cette personne n'est pas ton ami")

    db.delete(fr)
    db.commit()

    return {"message": "Ami retiré"}
