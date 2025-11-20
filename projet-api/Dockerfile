FROM python:3.11-slim

# Dossier de travail
WORKDIR /app

# Installer dépendances système dont netcat (pour nc dans entrypoint.sh)
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Installer les dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY . .

# Copier le script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exposer le port de l'API
EXPOSE 8000

# Utiliser le script d'entrée comme point d'entrée
ENTRYPOINT ["/entrypoint.sh"]
