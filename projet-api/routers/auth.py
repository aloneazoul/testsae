# routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, Form, UploadFile, File
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from database import get_db
import cloudinary
import cloudinary.uploader
import os
import database
import models
import password as auth  # ton fichier auth.py (hash_password, create_access_token, etc.)

router = APIRouter(tags=["Auth"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "dio0m73b8"),
    api_key=os.getenv("CLOUDINARY_API_KEY", "176583934591119"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET", "EwbWKNCXrzvYNVNGEG72c0nfBF0"),
)

class RegisterRequest(BaseModel):
    email: EmailStr
    pseudo: str
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str




def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> models.User:
    """
    Dépendance à réutiliser partout pour récupérer l'utilisateur connecté.
    """
    try:
        payload = jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        user_id = int(payload.get("sub"))
    except JWTError:
        raise HTTPException(status_code=401, detail="Token invalide "+token)

    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")

    return user


@router.post("/register")
def register(
    email: str = Form(...),
    pseudo: str = Form(...),
    gender: str = Form(...),
    phone: str = Form(...),
    password: str = Form(...),
    birthDate: str = Form(...),
    private: str = Form(...),
    bio: str = Form(None),
    imgFile: UploadFile = File(None),
    db: Session = Depends(database.get_db)
    ):
    if db.query(models.User).filter(models.User.email == email).first():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    user = models.User(
        email=email,
        username=pseudo,
        gender=gender,
        phone_number=phone,
        password_hash=auth.hash_password(password),
        birth_date=birthDate,
        is_private_flag=private
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    if bio is not None:
        user.bio = bio
        db.commit()
        
    if imgFile is not None:
        try:
            print("Upload image vers Cloudinary:", imgFile.filename)
            upload_result = cloudinary.uploader.upload(
                imgFile.file,
                folder=f"user_{user.user_id}/profile/",
                unique_filename=True,
                overwrite=True
            )
            user.profile_picture = upload_result["secure_url"]
            db.commit()
            print("✅ Upload OK")
        except Exception as e:
            import traceback
            traceback.print_exc()  # <- affiche l'erreur complète
            raise HTTPException(status_code=500, detail=f"Erreur upload Cloudinary : {e}")
    
    return {"message": "Utilisateur créé avec succès", "id": user.user_id}


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == req.email).first()

    if not user:
        raise HTTPException(status_code=401, detail="Email inconnu")

    if not auth.verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Mot de passe incorrect")

    token = auth.create_access_token({"sub": str(user.user_id)})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {"id": user.user_id, "pseudo": user.username},
    }
