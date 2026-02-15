# routers/messages.py

from fastapi import APIRouter, Depends, HTTPException, Form
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timezone

import database
import models
from .auth import get_current_user
from .notifications import create_notification

router = APIRouter(tags=["Messages"])


# ============================================================
# 🔒 MESSAGES PRIVÉS
# ============================================================

@router.get("/messages/conversations")
def get_my_conversations(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Récupère la liste des conversations (dernier message pour chaque contact).
    """
    # Cette requête SQL récupère le dernier message échangé avec chaque interlocuteur
    sql = text("""
        WITH LastMsgs AS (
            SELECT 
                CASE WHEN sender_id = :uid THEN receiver_id ELSE sender_id END AS partner_id,
                MAX(sent_at) as max_date
            FROM private_messages
            WHERE sender_id = :uid OR receiver_id = :uid
            GROUP BY partner_id
        )
        SELECT 
            u.user_id, 
            u.username, 
            u.profile_picture,
            pm.content,
            pm.sent_at,
            pm.is_read_flag,
            pm.sender_id
        FROM LastMsgs lm
        JOIN users u ON u.user_id = lm.partner_id
        JOIN private_messages pm ON 
            (pm.sender_id = :uid AND pm.receiver_id = lm.partner_id AND pm.sent_at = lm.max_date)
            OR 
            (pm.sender_id = lm.partner_id AND pm.receiver_id = :uid AND pm.sent_at = lm.max_date)
        ORDER BY lm.max_date DESC;
    """)
    
    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


@router.post("/messages/private")
def send_private_message(
    receiver_id: int = Form(...),
    content: str = Form(None),
    media_url: str = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    if receiver_id == current_user.user_id:
        raise HTTPException(400, "Tu ne peux pas t'envoyer un message à toi-même")

    receiver = db.query(models.User).filter_by(user_id=receiver_id).first()
    if not receiver:
        raise HTTPException(404, "Destinataire introuvable")

    pm = models.PrivateMessage(
        sender_id=current_user.user_id,
        receiver_id=receiver_id,
        content=content,
        media_url=media_url,
        sent_at=datetime.now(timezone.utc),
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
        is_read_flag="N",
    )
    db.add(pm)
    db.commit()
    db.refresh(pm)
    
    # 🔔 notif au destinataire
    create_notification(
        db=db,
        target_user_id=receiver_id,
        notif_type="MESSAGE",
        notif_text=f"Nouveau message de {current_user.username}",
        related_id=pm.private_message_id,
        related_table="private_messages",
        creator_id=current_user.user_id,
    )

    return {"message": "Message envoyé", "private_message_id": pm.private_message_id}


@router.get("/messages/private/{user_id}")
def get_private_conversation(
    user_id: int,
    limit: int = 100,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Récupère la conversation entre l'utilisateur courant et user_id
    """
    sql = text("""
        SELECT pm.*, 
               s.username AS sender_username,
               r.username AS receiver_username
        FROM private_messages pm
        JOIN users s ON s.user_id = pm.sender_id
        JOIN users r ON r.user_id = pm.receiver_id
        WHERE (pm.sender_id = :me AND pm.receiver_id = :other)
           OR (pm.sender_id = :other AND pm.receiver_id = :me)
        ORDER BY pm.sent_at DESC
        LIMIT :limit;
    """)

    res = db.execute(
        sql,
        {"me": current_user.user_id, "other": user_id, "limit": limit},
    ).mappings().all()

    return list(res)


@router.get("/messages/private/unread")
def get_unread_messages(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    sql = text("""
        SELECT pm.*, u.username AS sender_username
        FROM private_messages pm
        JOIN users u ON u.user_id = pm.sender_id
        WHERE pm.receiver_id = :me AND pm.is_read_flag = 'N'
        ORDER BY pm.sent_at DESC;
    """)
    res = db.execute(sql, {"me": current_user.user_id}).mappings().all()
    return list(res)


@router.post("/messages/private/{message_id}/read")
def mark_message_read(
    message_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    pm = db.query(models.PrivateMessage).filter_by(private_message_id=message_id).first()
    if not pm:
        raise HTTPException(404, "Message introuvable")

    if pm.receiver_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux marquer comme lu que tes messages reçus")

    pm.is_read_flag = "Y"
    pm.last_modification_date = datetime.now(timezone.utc)
    pm.last_modified_by = current_user.user_id

    db.commit()
    return {"message": "Message marqué comme lu"}


# ============================================================
# 👥 GROUPES - GESTION DES GROUPES
# ============================================================

@router.post("/groups")
def create_group(
    group_name: str = Form(...),
    description: str = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    group = models.GroupChat(
        group_name=group_name,
        description=description,
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
        last_modification_date=datetime.now(timezone.utc),
        last_modified_by=current_user.user_id,
    )
    db.add(group)
    db.commit()
    db.refresh(group)

    # Ajoute le créateur comme ADMIN dans group_members
    member = models.GroupMember(
        group_chat_id=group.group_chat_id,
        user_id=current_user.user_id,
        role="ADMIN",
        join_date=datetime.now(timezone.utc),
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
    )
    db.add(member)
    db.commit()

    return {"message": "Groupe créé", "group_chat_id": group.group_chat_id}


@router.post("/groups/{group_id}/join")
def join_group(
    group_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    group = db.query(models.GroupChat).filter_by(group_chat_id=group_id).first()
    if not group:
        raise HTTPException(404, "Groupe introuvable")

    existing = db.query(models.GroupMember).filter_by(
        group_chat_id=group_id,
        user_id=current_user.user_id,
    ).first()

    if existing:
        return {"message": "Déjà membre du groupe"}

    member = models.GroupMember(
        group_chat_id=group_id,
        user_id=current_user.user_id,
        role="MEMBER",
        join_date=datetime.now(timezone.utc),
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
    )
    db.add(member)
    db.commit()

    return {"message": "Tu as rejoint le groupe"}


@router.post("/groups/{group_id}/leave")
def leave_group(
    group_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    member = db.query(models.GroupMember).filter_by(
        group_chat_id=group_id,
        user_id=current_user.user_id,
    ).first()

    if not member:
        raise HTTPException(404, "Tu n'es pas membre de ce groupe")

    db.delete(member)
    db.commit()

    return {"message": "Tu as quitté le groupe"}


@router.get("/groups/my")
def my_groups(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    sql = text("""
        SELECT gc.group_chat_id, gc.group_name, gc.description
        FROM group_members gm
        JOIN group_chats gc ON gc.group_chat_id = gm.group_chat_id
        WHERE gm.user_id = :uid
        ORDER BY gc.creation_date DESC;
    """)
    res = db.execute(sql, {"uid": current_user.user_id}).mappings().all()
    return list(res)


@router.get("/groups/{group_id}/members")
def list_group_members(
    group_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    # Optionnel : vérifier que current_user est dans le groupe
    members = (
        db.query(models.GroupMember)
        .filter(models.GroupMember.group_chat_id == group_id)
        .all()
    )
    return members


# ============================================================
# 💬 MESSAGES DE GROUPE
# ============================================================

@router.post("/groups/{group_id}/messages")
def send_group_message(
    group_id: int,
    message_text: str = Form(None),
    media_url: str = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    # Vérifier que le groupe existe
    group = db.query(models.GroupChat).filter_by(group_chat_id=group_id).first()
    if not group:
        raise HTTPException(404, "Groupe introuvable")

    # Vérifier que l'utilisateur est bien membre
    member = db.query(models.GroupMember).filter_by(
        group_chat_id=group_id,
        user_id=current_user.user_id,
    ).first()
    if not member:
        raise HTTPException(403, "Tu dois rejoindre le groupe pour envoyer un message")

    gm = models.GroupMessage(
        group_chat_id=group_id,
        sender_id=current_user.user_id,
        message_text=message_text,
        media_url=media_url,
        sent_at=datetime.now(timezone.utc),
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
    )
    db.add(gm)
    db.commit()
    db.refresh(gm)

    return {"message": "Message envoyé", "group_message_id": gm.group_message_id}


@router.get("/groups/{group_id}/messages")
def get_group_messages(
    group_id: int,
    limit: int = 100,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    # Vérifier que le groupe existe
    group = db.query(models.GroupChat).filter_by(group_chat_id=group_id).first()
    if not group:
        raise HTTPException(404, "Groupe introuvable")

    # Option : vérifier que l'utilisateur est membre
    member = db.query(models.GroupMember).filter_by(
        group_chat_id=group_id,
        user_id=current_user.user_id,
    ).first()
    if not member:
        raise HTTPException(403, "Tu dois être membre du groupe pour voir les messages")

    sql = text("""
        SELECT gm.*, u.username AS sender_username
        FROM group_messages gm
        JOIN users u ON u.user_id = gm.sender_id
        WHERE gm.group_chat_id = :gid
        ORDER BY gm.sent_at DESC
        LIMIT :limit;
    """)
    res = db.execute(sql, {"gid": group_id, "limit": limit}).mappings().all()
    return list(res)

@router.post("/messages/private/read_all/{sender_id}")
def mark_conversation_read(
    sender_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """
    Marque tous les messages reçus de 'sender_id' comme lus (is_read_flag = 'Y').
    """
    # Mise à jour de masse (UPDATE)
    db.query(models.PrivateMessage).filter(
        models.PrivateMessage.sender_id == sender_id,
        models.PrivateMessage.receiver_id == current_user.user_id,
        models.PrivateMessage.is_read_flag == 'N'
    ).update({models.PrivateMessage.is_read_flag: "Y"}, synchronize_session=False)

    db.commit()
    return {"message": "Conversation marquée comme lue"}