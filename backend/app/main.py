from fastapi import FastAPI
from . import models, database
from .routers import livres, utilisateurs # Importez utilisateurs

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI()

app.include_router(livres.router)
app.include_router(utilisateurs.router) # Ajoutez cette ligne

@app.get("/")
def root():
    return {"message": "Bienvenue sur l'API de la Bibliothèque"}