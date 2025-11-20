from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    pseudo = Column(String(255), nullable=False)
    password_hash = Column(String(255), nullable=False)
    photos = relationship("Photo", back_populates="user")


class Photo(Base):
    __tablename__ = "photos"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    url = Column(String(255), nullable=False)
    public_id = Column(String(255), unique=True)
    user = relationship("User", back_populates="photos")