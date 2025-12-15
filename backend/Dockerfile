# Utilisation d'une image Python en version 11
FROM python:3.11-slim

# Création du dossier de travail
WORKDIR /backend

# Copie du fichier requirements.txt
COPY ./requirements.txt ./requirements.txt

# Installation des dépendances
RUN pip install -r requirements.txt

# Copie de l'application
COPY ./app /backend/app

# Exposition du port 
EXPOSE 8000

# Lancement du serveur 
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]