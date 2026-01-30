from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

from sqlalchemy import (
    Column, Integer, String, Text, Date, DateTime, ForeignKey, CheckConstraint, Boolean, DECIMAL, JSON, BigInteger, UniqueConstraint
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base


# models.py

from sqlalchemy import Column, Integer, String, Text, Date, DateTime, ForeignKey, CheckConstraint, CHAR
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from database import Base


class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    gender = Column(String(50), nullable=True)  # Homme / Femme / Autre
    bio = Column(Text, nullable=True)

    is_private_flag = Column(CHAR(1), default='N', nullable=False)
    is_active_flag = Column(CHAR(1), default='Y', nullable=False)
    email_verified_flag = Column(CHAR(1), default='N', nullable=False)

    email = Column(String(255), unique=True, nullable=False)
    phone_number = Column(String(20), nullable=True)

    password_hash = Column(String(255), nullable=False)

    birth_date = Column(Date, nullable=True)
    profile_picture = Column(String(255), nullable=True)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    # Relations internes (auto‐références)
    created_by_user = relationship("User", remote_side=[user_id], foreign_keys=[created_by])
    last_modified_by_user = relationship("User", remote_side=[user_id], foreign_keys=[last_modified_by])

    # CONSTRAINTS
    __table_args__ = (
        CheckConstraint("is_private_flag IN ('Y', 'N')", name="chk_user_private"),
        CheckConstraint("is_active_flag IN ('Y', 'N')", name="chk_user_active"),
        CheckConstraint("email_verified_flag IN ('Y', 'N')", name="chk_email_verified"),
    )


class UserPreferences(Base):
    __tablename__ = "user_preferences"

    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    theme = Column(String(20), default="AUTO", nullable=False)  # LIGHT / DARK / AUTO
    language = Column(String(5), default="FR", nullable=False)  # FR / EN / ES
    notifications_enabled = Column(Boolean, default=True)
    location_sharing_enabled = Column(Boolean, default=True)
    show_on_map = Column(Boolean, default=True)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", backref="preferences", uselist=False)

    __table_args__ = (
        CheckConstraint("theme IN ('LIGHT', 'DARK', 'AUTO')", name="chk_theme"),
    )


class Country(Base):
    __tablename__ = "countries"

    country_id = Column(Integer, primary_key=True, index=True)
    country_code = Column(String(3), unique=True, nullable=False)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    translations = relationship("CountryTranslation", back_populates="country")



class CountryTranslation(Base):
    __tablename__ = "country_tl"

    country_id = Column(Integer, ForeignKey("countries.country_id"), primary_key=True)
    language_code = Column(String(5), primary_key=True)
    country_name = Column(String(100), nullable=False)

    country = relationship("Country", back_populates="translations")



class City(Base):
    __tablename__ = "cities"

    city_id = Column(Integer, primary_key=True, index=True)
    city_name = Column(String(100), nullable=False)
    city_street = Column(String(100), nullable=True)

    country_id = Column(Integer, ForeignKey("countries.country_id"), nullable=False)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    places = relationship("Place", back_populates="city")




class Place(Base):
    __tablename__ = "places"

    place_id = Column(Integer, primary_key=True, index=True)
    place_name = Column(String(100), nullable=False)
    latitude = Column(DECIMAL(9, 6), nullable=False)
    longitude = Column(DECIMAL(9, 6), nullable=False)

    city_id = Column(Integer, ForeignKey("cities.city_id"), nullable=False)

    external_place_id = Column(String(100))

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    city = relationship("City", back_populates="places")


class Friend(Base):
    __tablename__ = "friends"

    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    user_id_friend = Column(Integer, ForeignKey("users.user_id"), primary_key=True)

    status = Column(String(20), nullable=False, default="PENDING")  # PENDING / ACCEPTED / REJECTED

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    __table_args__ = (
        CheckConstraint("status IN ('PENDING', 'ACCEPTED', 'REJECTED')", name="chk_friend_status"),
    )


class FriendHistory(Base):
    __tablename__ = "friends_hist"

    friends_hist_id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    user_id_friend = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    status = Column(String(20), nullable=False)  # PENDING / ACCEPTED / REJECTED
    changed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    changed_by = Column(Integer, ForeignKey("users.user_id"))

    __table_args__ = (
        CheckConstraint("status IN ('PENDING', 'ACCEPTED', 'REJECTED')", name="chk_friend_hist_status"),
    )



class Follower(Base):
    __tablename__ = "followers"

    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    follower_user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)

    status = Column(String(20), nullable=False, default="ACCEPTED")  
    # PENDING → demandes d’abonnement (si mode privé)
    # ACCEPTED → abonné
    # REJECTED → refusé

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    __table_args__ = (
        CheckConstraint("status IN ('PENDING', 'ACCEPTED', 'REJECTED')", name="chk_follower_status"),
    )



class Trip(Base):
    __tablename__ = "trips"

    trip_id = Column(Integer, primary_key=True, index=True)
    trip_title = Column(String(100), nullable=False)
    trip_description = Column(Text, nullable=True)

    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)

    is_public_flag = Column(CHAR(1), default="Y", nullable=False)

    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    banner = Column(String(255), nullable=True)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    __table_args__ = (
        CheckConstraint("is_public_flag IN ('Y', 'N')", name="chk_trip_public"),
    )

    places = relationship("TripPlace", back_populates="trip")


class TripHistory(Base):
    __tablename__ = "trips_hist"

    trips_hist_id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.trip_id"), nullable=False)

    trip_title = Column(String(100))
    trip_description = Column(Text)
    start_date = Column(Date)
    end_date = Column(Date)
    is_public_flag = Column(CHAR(1))
    banner = Column(String(255), nullable=True)

    changed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    changed_by = Column(Integer, ForeignKey("users.user_id"))


class TripPlace(Base):
    __tablename__ = "trip_places"

    trip_id = Column(Integer, ForeignKey("trips.trip_id"), primary_key=True)
    place_id = Column(Integer, ForeignKey("places.place_id"), primary_key=True)

    visited_at = Column(DateTime, nullable=True)
    ordinal = Column(Integer, nullable=True)

    trip = relationship("Trip", back_populates="places")
    place = relationship("Place")



class Post(Base):
    __tablename__ = "posts"

    post_id = Column(Integer, primary_key=True, index=True)
    post_title = Column(String(100))
    post_description = Column(Text)
    publication_date = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # NOUVEAU : Type de post (POST ou MEMORY)
    post_type = Column(String(20), default="POST", nullable=False)

    privacy = Column(String(20), default="PUBLIC", nullable=False)  
    allow_comments_flag = Column(CHAR(1), default="Y", nullable=False)

    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    trip_id = Column(Integer, ForeignKey("trips.trip_id"), nullable=True)
    place_id = Column(Integer, ForeignKey("places.place_id"), nullable=True)

    latitude = Column(DECIMAL(9, 6))
    longitude = Column(DECIMAL(9, 6))

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    __table_args__ = (
        CheckConstraint("privacy IN ('PUBLIC', 'FRIENDS', 'PRIVATE')", name="chk_post_privacy"),
        CheckConstraint("allow_comments_flag IN ('Y', 'N')", name="chk_allow_comments"),
        CheckConstraint("post_type IN ('POST', 'MEMORY')", name="chk_post_type"),
    )

    media = relationship("Media", back_populates="post")



class Media(Base):
    __tablename__ = "media"

    media_id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=False)

    media_url = Column(String(255), nullable=False)
    thumbnail_url = Column(String(255))
    media_type = Column(String(20), nullable=False)

    storage_path = Column(String(255))
    cloud_id = Column(String(255))

    size = Column(BigInteger)
    width = Column(Integer)
    height = Column(Integer)
    duration_seconds = Column(Integer)
    original_filename = Column(String(255))
    exif_data = Column(JSON)

    carrousel_rank = Column(Integer, default=1)

    upload_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"))
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    __table_args__ = (
        CheckConstraint("media_type IN ('IMAGE', 'VIDEO')", name="chk_media_type"),
    )

    post = relationship("Post", back_populates="media")



class Story(Base):
    __tablename__ = "stories"

    story_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    media_url = Column(String(255), nullable=False)
    thumbnail_url = Column(String(255))
    media_type = Column(String(20), nullable=False)
    caption = Column(Text)

    latitude = Column(DECIMAL(9, 6))
    longitude = Column(DECIMAL(9, 6))

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime, nullable=False)

    view_count = Column(Integer, default=0)

    __table_args__ = (
        CheckConstraint("media_type IN ('IMAGE', 'VIDEO')", name="chk_story_media_type"),
    )


class StoryView(Base):
    __tablename__ = "story_views"

    story_id = Column(Integer, ForeignKey("stories.story_id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    viewed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


    # optionnel pour naviguer
    # story = relationship("Story")
    # user = relationship("User")


class Like(Base):
    __tablename__ = "likes"

    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    # post = relationship("Post")
    # user = relationship("User")


class Mention(Base):
    __tablename__ = "mentions"

    mention_id = Column(Integer, primary_key=True, index=True)

    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=True)
    comment_id = Column(Integer, ForeignKey("comments.comment_id", ondelete="CASCADE"), nullable=True)

    mentioned_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    mentioned_by_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    mention_position = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        CheckConstraint(
            "(post_id IS NOT NULL AND comment_id IS NULL) OR (post_id IS NULL AND comment_id IS NOT NULL)",
            name="chk_mentions_post_or_comment",
        ),
    )


class SavedPost(Base):
    __tablename__ = "saved_posts"

    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), primary_key=True)

    saved_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


class PostShare(Base):
    __tablename__ = "post_shares"

    post_share_id = Column(Integer, primary_key=True, index=True)

    post_id = Column(Integer, ForeignKey("posts.post_id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    share_type = Column(String(20), nullable=False)  # DIRECT_MESSAGE / STORY / REPOST
    message = Column(Text, nullable=True)

    shared_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    __table_args__ = (
        CheckConstraint(
            "share_type IN ('DIRECT_MESSAGE', 'STORY', 'REPOST')",
            name="chk_share_type",
        ),
    )


class Comment(Base):
    __tablename__ = "comments"

    comment_id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    parent_comment_id = Column(Integer, ForeignKey("comments.comment_id"), nullable=True)

    content = Column(Text, nullable=False)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    # Relations optionnelles
    # post = relationship("Post", backref="comments")
    # user = relationship("User")
    # parent = relationship("Comment", remote_side=[comment_id], backref="replies")


class UserInteraction(Base):
    __tablename__ = "user_interactions"

    interaction_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.post_id", ondelete="CASCADE"), nullable=False)

    interaction_type = Column(String(20), nullable=False)  # VIEW / LIKE / SHARE / SAVE / COMMENT / SKIP
    duration_seconds = Column(Integer)

    interaction_date = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        CheckConstraint(
            "interaction_type IN ('VIEW', 'LIKE', 'SHARE', 'SAVE', 'COMMENT', 'SKIP')",
            name="chk_interaction_type",
        ),
    )

class PrivateMessage(Base):
    __tablename__ = "private_messages"

    private_message_id = Column(Integer, primary_key=True, index=True)

    sender_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    content = Column(Text)
    media_url = Column(String(255))

    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    is_read_flag = Column(CHAR(1), default="N", nullable=False)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    __table_args__ = (
        CheckConstraint("is_read_flag IN ('Y', 'N')", name="chk_pm_read"),
    )



class GroupChat(Base):
    __tablename__ = "group_chats"

    group_chat_id = Column(Integer, primary_key=True, index=True)
    group_name = Column(String(100), nullable=False)
    description = Column(Text)

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)


class GroupMember(Base):
    __tablename__ = "group_members"

    group_member_id = Column(Integer, primary_key=True, index=True)

    group_chat_id = Column(Integer, ForeignKey("group_chats.group_chat_id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    join_date = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


    role = Column(String(20), default="MEMBER", nullable=False)  # ADMIN / MODERATOR / MEMBER

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    __table_args__ = (
        UniqueConstraint("group_chat_id", "user_id", name="uq_group_member"),
        CheckConstraint(
            "role IN ('ADMIN', 'MODERATOR', 'MEMBER')",
            name="chk_group_role",
        ),
    )


class GroupMessage(Base):
    __tablename__ = "group_messages"

    group_message_id = Column(Integer, primary_key=True, index=True)

    group_chat_id = Column(Integer, ForeignKey("group_chats.group_chat_id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    message_text = Column(Text)
    media_url = Column(String(255))

    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)


    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)



class Notification(Base):
    __tablename__ = "notifications"

    notification_id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    notification_text = Column(Text)
    notification_type = Column(String(20), nullable=False)  # LIKE / COMMENT / FRIEND_REQUEST...

    related_id = Column(Integer)  # id du post / commentaire / user / message...
    related_table = Column(String(50))  # 'posts', 'comments', 'users', etc.

    creation_date = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    last_modification_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_modified_by = Column(Integer, ForeignKey("users.user_id"))

    is_read_flag = Column(CHAR(1), default="N", nullable=False)

    __table_args__ = (
        CheckConstraint("is_read_flag IN ('Y','N')", name="chk_notif_read"),
        CheckConstraint(
            "notification_type IN ('LIKE','COMMENT','FRIEND_REQUEST','FOLLOW','MENTION','MESSAGE','SHARED_POST')",
            name="chk_notif_type"
        ),
    )



class MapFeed(Base):
    __tablename__ = "map_feed"

    post_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    username = Column(String(50))
    profile_picture = Column(String(255))

    latitude = Column(DECIMAL(9, 6), index=True)
    longitude = Column(DECIMAL(9, 6), index=True)

    post_title = Column(String(100))
    post_description = Column(Text)
    publication_date = Column(DateTime, index=True)

    preview_image = Column(String(255))
    place_name = Column(String(100))
    city_name = Column(String(100))
    country_code = Column(String(3))

    likes_count = Column(Integer)

# NOUVEAU : Table pour liker les commentaires
class CommentLike(Base):
    __tablename__ = "comment_likes"
    
    comment_id = Column(Integer, ForeignKey("comments.comment_id", ondelete="CASCADE"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    
    liked_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))