# routers/followers.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone

import database
import models
from .auth import get_current_user
from .notifications import create_notification

router = APIRouter(tags=["Followers"])

# ============================================================
# HELPER : GÉRER L'AMITIÉ AUTOMATIQUE
# ============================================================
def check_and_create_friendship(db: Session, user_a_id: int, user_b_id: int):
    """
    Vérifie si A suit B et B suit A. Si oui, crée une amitié (Friends).
    """
    # 1. Est-ce que A suit B (ACCEPTED) ?
    follow_a_to_b = db.query(models.Follower).filter_by(
        user_id=user_b_id, follower_user_id=user_a_id, status="ACCEPTED"
    ).first()

    # 2. Est-ce que B suit A (ACCEPTED) ?
    follow_b_to_a = db.query(models.Follower).filter_by(
        user_id=user_a_id, follower_user_id=user_b_id, status="ACCEPTED"
    ).first()

    # Si les deux se suivent mutuellement
    if follow_a_to_b and follow_b_to_a:
        # On vérifie si l'amitié existe déjà pour éviter les doublons
        existing_friend = db.query(models.Friend).filter_by(
            user_id=user_a_id, user_id_friend=user_b_id
        ).first()

        if not existing_friend:
            # On crée l'amitié dans les deux sens (pour simplifier les requêtes SQL plus tard)
            f1 = models.Friend(
                user_id=user_a_id, user_id_friend=user_b_id, status="ACCEPTED",
                created_by=user_a_id, last_modified_by=user_a_id
            )
            f2 = models.Friend(
                user_id=user_b_id, user_id_friend=user_a_id, status="ACCEPTED",
                created_by=user_b_id, last_modified_by=user_b_id
            )
            db.add_all([f1, f2])
            db.commit()
            
            # Notification "Vous êtes désormais amis"
            create_notification(db, user_a_id, "FRIEND_REQUEST", f"Vous et {follow_b_to_a.user.username} êtes désormais amis !", user_b_id, "users", user_b_id)
            create_notification(db, user_b_id, "FRIEND_REQUEST", f"Vous et {follow_a_to_b.user.username} êtes désormais amis !", user_a_id, "users", user_a_id)
            print(f"✅ Amitié créée entre {user_a_id} et {user_b_id}")


def remove_friendship(db: Session, user_a_id: int, user_b_id: int):
    """
    Si l'un des deux arrête de suivre l'autre, l'amitié est rompue.
    """
    friends = db.query(models.Friend).filter(
        or_(
            (models.Friend.user_id == user_a_id) & (models.Friend.user_id_friend == user_b_id),
            (models.Friend.user_id == user_b_id) & (models.Friend.user_id_friend == user_a_id)
        )
    ).all()

    if friends:
        for f in friends:
            db.delete(f)
        db.commit()
        print(f"💔 Amitié supprimée entre {user_a_id} et {user_b_id}")


# ============================================================
# 1. SUIVRE UN UTILISATEUR
# ============================================================
@router.post("/follow/{user_id}")
def follow_user(
    user_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    if user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Tu ne peux pas te suivre toi-même")

    target = db.query(models.User).filter_by(user_id=user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    # Vérifier s'il existe déjà une relation
    rel = db.query(models.Follower).filter_by(
        user_id=user_id,
        follower_user_id=current_user.user_id
    ).first()

    if rel:
        if rel.status == "ACCEPTED":
            return {"message": "Tu suis déjà cet utilisateur"}
        if rel.status == "PENDING":
            return {"message": "Demande déjà en attente"}
        if rel.status == "REJECTED":
            # On autorise à renvoyer une demande
            pass

    # Compte privé → PENDING, sinon ACCEPTED
    status = "PENDING" if target.is_private_flag == "Y" else "ACCEPTED"

    if not rel:
        rel = models.Follower(
            user_id=user_id,
            follower_user_id=current_user.user_id,
            status=status,
            created_by=current_user.user_id,
            last_modified_by=current_user.user_id,
            last_modification_date=datetime.now(timezone.utc),
        )
        db.add(rel)
    else:
        rel.status = status
        rel.last_modified_by = current_user.user_id
        rel.last_modification_date = datetime.now(timezone.utc)

    db.commit()
    # 🔔 notif au user suivi
    if user_id != current_user.user_id:
        txt = "a demandé à vous suivre" if status == "PENDING" else "a commencé à vous suivre"
        create_notification(
            db=db,
            target_user_id=user_id,
            notif_type="FOLLOW",
            notif_text=f"{current_user.username} {txt}",
            related_id=current_user.user_id,
            related_table="users",
            creator_id=current_user.user_id,
        )
    
    if status == "PENDING":
        return {"message": "Demande d’abonnement envoyée"}
    else:
        return {"message": "Tu suis maintenant cet utilisateur"}


# ============================================================
# 2. VOIR LES DEMANDES D’ABONNEMENT (PENDING)
# ============================================================
@router.get("/followers/requests")
def list_follower_requests(
    type: str = Query("incoming", enum=["incoming", "outgoing"]),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    incoming : les gens qui demandent à ME suivre
    outgoing : les demandes que J'AI faites à d'autres
    """
    if type == "incoming":
        sql = text("""
            SELECT u.user_id, u.username, u.profile_picture, f.creation_date
            FROM followers f
            JOIN users u ON u.user_id = f.follower_user_id
            WHERE f.user_id = :uid AND f.status = 'PENDING';
        """)
    else:
        sql = text("""
            SELECT u.user_id, u.username, u.profile_picture, f.creation_date
            FROM followers f
            JOIN users u ON u.user_id = f.user_id
            WHERE f.follower_user_id = :uid AND f.status = 'PENDING';
        """)

    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 3. ACCEPTER UNE DEMANDE D’ABONNEMENT (COMPTE PRIVÉ)
# ============================================================
@router.post("/followers/requests/{follower_id}/accept")
def accept_follower_request(
    follower_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    follower_id = l'utilisateur qui a demandé à me suivre.
    """
    f = db.query(models.Follower).filter_by(
        user_id=current_user.user_id,
        follower_user_id=follower_id,
        status="PENDING",
    ).first()

    if not f:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    f.status = "ACCEPTED"
    f.last_modified_by = current_user.user_id
    f.last_modification_date = datetime.now(timezone.utc)

    db.commit()
    return {"message": "Abonné accepté"}


# ============================================================
# 4. REJETER UNE DEMANDE D’ABONNEMENT
# ============================================================
@router.post("/followers/requests/{follower_id}/reject")
def reject_follower_request(
    follower_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    f = db.query(models.Follower).filter_by(
        user_id=current_user.user_id,
        follower_user_id=follower_id,
        status="PENDING",
    ).first()

    if not f:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    f.status = "REJECTED"
    f.last_modified_by = current_user.user_id
    f.last_modification_date = datetime.now(timezone.utc)

    db.commit()
    return {"message": "Demande rejetée"}


# ============================================================
# 5. LISTER MES FOLLOWERS
# ============================================================
@router.get("/followers")
def list_followers(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Les gens qui ME suivent (status = ACCEPTED).
    """
    sql = text("""
        SELECT u.user_id, u.username, u.profile_picture
        FROM followers f
        JOIN users u ON u.user_id = f.follower_user_id
        WHERE f.user_id = :uid AND f.status = 'ACCEPTED';
    """)
    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 6. LISTER CEUX QUE JE SUIS (FOLLOWING)
# ============================================================
@router.get("/following")
def list_following(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Les gens que JE suis (status = ACCEPTED).
    """
    sql = text("""
        SELECT u.user_id, u.username, u.profile_picture
        FROM followers f
        JOIN users u ON u.user_id = f.user_id
        WHERE f.follower_user_id = :uid AND f.status = 'ACCEPTED';
    """)
    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


# ============================================================
# 7. SE DÉSABONNER (UNFOLLOW)
# ============================================================
@router.delete("/follow/{user_id}")
def unfollow_user(
    user_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Je ne veux plus suivre user_id.
    """
    f = db.query(models.Follower).filter_by(
        user_id=user_id,
        follower_user_id=current_user.user_id,
    ).first()

    if not f:
        raise HTTPException(status_code=404, detail="Tu ne suis pas cet utilisateur")

    db.delete(f)
    db.commit()

    return {"message": "Désabonnement effectué"}
