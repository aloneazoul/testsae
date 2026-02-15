#!/bin/sh
set -e

DB_PASSWORD="$(cat /run/secrets/mysql_password)"

export DATABASE_URL="mysql+pymysql://spotshare:${DB_PASSWORD}@db:3306/spotshare"
echo "DATABASE_URL configurée : $DATABASE_URL"

until nc -z db 3306; do
  echo "En attente de la base de données MySQL..."
  sleep 2
done

exec uvicorn main:app --host 0.0.0.0 --port 8000
