from fastapi import FastAPI
from sqlalchemy import text
from app.db.session import engine, get_db
from fastapi import Depends
from sqlalchemy.orm import Session

# Import des routes
from app.routes import user_routes

app = FastAPI(title="API Bibliothèque")

# Inclusion des routes utilisateurs
app.include_router(user_routes.router)

# Route racine
@app.get("/")
async def root():
    return {"message": "Bienvenue sur l'API Bibliothèque"}
