# routers/comments.py

from fastapi import APIRouter, Depends, HTTPException, Form
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from .notifications import create_notification

import database
import models
from .auth import get_current_user

router = APIRouter(tags=["Comments"])


@router.get("/posts/{post_id}/comments")
def list_comments(
    post_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user), 
):
    # On fait une jointure entre Comment et User pour récupérer pseudo + avatar
    results = (
        db.query(models.Comment, models.User)
        .join(models.User, models.Comment.user_id == models.User.user_id)
        .filter(models.Comment.post_id == post_id)
        .order_by(models.Comment.creation_date.asc())
        .all()
    )

    comments_list = []
    for comment, user in results:
        likes_count = db.query(models.CommentLike).filter(models.CommentLike.comment_id == comment.comment_id).count()
        
        is_liked = db.query(models.CommentLike).filter(
            models.CommentLike.comment_id == comment.comment_id,
            models.CommentLike.user_id == current_user.user_id
        ).first() is not None

        comments_list.append({
            "comment_id": comment.comment_id,
            "post_id": comment.post_id,
            "user_id": comment.user_id,
            "content": comment.content,
            "created_at": comment.creation_date,
            "username": user.username,
            "profile_picture": user.profile_picture,
            "parent_comment_id": comment.parent_comment_id, # AJOUT CRUCIAL
            "likes_count": likes_count,
            "is_liked": is_liked
        })
    
    return comments_list


@router.post("/posts/{post_id}/comments")
def create_comment(
    post_id: int,
    content: str = Form(...),
    parent_comment_id: int = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    post = db.query(models.Post).filter_by(post_id=post_id).first()
    if not post:
        raise HTTPException(404, "Post introuvable")

    if parent_comment_id is not None:
        parent = db.query(models.Comment).filter_by(comment_id=parent_comment_id).first()
        if not parent:
            raise HTTPException(404, "Commentaire parent introuvable")

    comment = models.Comment(
        post_id=post_id,
        user_id=current_user.user_id,
        parent_comment_id=parent_comment_id,
        content=content,
        creation_date=datetime.now(timezone.utc),
        created_by=current_user.user_id,
        last_modification_date=datetime.now(timezone.utc),
        last_modified_by=current_user.user_id,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    
    if post.user_id != current_user.user_id:
        create_notification(
            db=db,
            target_user_id=post.user_id,
            notif_type="COMMENT",
            notif_text=f"{current_user.username} a commenté votre post",
            related_id=post.post_id,
            related_table="posts",
            creator_id=current_user.user_id,
        )

    if parent_comment_id is not None and parent.user_id not in (None, current_user.user_id, post.user_id):
        create_notification(
            db=db,
            target_user_id=parent.user_id,
            notif_type="COMMENT",
            notif_text=f"{current_user.username} a répondu à votre commentaire",
            related_id=comment.comment_id,
            related_table="comments",
            creator_id=current_user.user_id,
        )
        
    return {"message": "Commentaire créé", "comment_id": comment.comment_id}


@router.delete("/comments/{comment_id}")
def delete_comment(
    comment_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    comment = db.query(models.Comment).filter_by(comment_id=comment_id).first()
    if not comment:
        raise HTTPException(404, "Commentaire introuvable")

    if comment.user_id != current_user.user_id:
        raise HTTPException(403, "Tu ne peux supprimer que tes commentaires")

    db.delete(comment)
    db.commit()

    return {"message": "Commentaire supprimé"}


@router.post("/comments/{comment_id}/like")
def like_comment(
    comment_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    comment = db.query(models.Comment).filter_by(comment_id=comment_id).first()
    if not comment:
        raise HTTPException(404, "Commentaire introuvable")

    existing_like = db.query(models.CommentLike).filter_by(
        comment_id=comment_id, 
        user_id=current_user.user_id
    ).first()

    if existing_like:
        return {"message": "Déjà liké"}

    new_like = models.CommentLike(
        comment_id=comment_id, 
        user_id=current_user.user_id
    )
    db.add(new_like)
    db.commit()

    if comment.user_id != current_user.user_id:
        create_notification(
            db=db,
            target_user_id=comment.user_id,
            notif_type="LIKE",
            notif_text=f"{current_user.username} a aimé votre commentaire",
            related_id=comment.comment_id,
            related_table="comments",
            creator_id=current_user.user_id,
        )

    return {"message": "Commentaire liké"}


@router.delete("/comments/{comment_id}/like")
def unlike_comment(
    comment_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    like = db.query(models.CommentLike).filter_by(
        comment_id=comment_id, 
        user_id=current_user.user_id
    ).first()

    if not like:
        raise HTTPException(404, "Like introuvable")

    db.delete(like)
    db.commit()

    return {"message": "Like supprimé"}