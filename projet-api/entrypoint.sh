#!/bin/sh
set -e

# Lire le mot de passe depuis le secret Docker
DB_PASSWORD=$(cat /run/secrets/db_password)

# Construire la variable DATABASE_URL
export DATABASE_URL="postgresql://spotshare:${DB_PASSWORD}@db:5432/spotshare"
echo "DATABASE_URL configurée : $DATABASE_URL"

# Attendre que la base de données soit prête
until nc -z db 5432; do
  echo "En attente de la base de données..."
  sleep 2
done

# Lancer Uvicorn
exec uvicorn main:app --host 0.0.0.0 --port 8000
