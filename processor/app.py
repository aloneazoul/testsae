from flask import Flask, request, jsonify
import pandas as pd
import requests
import os
import json


app = Flask(__name__)

# Nom du service C# dans le docker network
INTERFACE_DB_HOST = os.getenv("INTERFACE_DB_HOST", "interface_db")
INTERFACE_DB_PORT = os.getenv("INTERFACE_DB_PORT", "5000")
BASE_URL = f"http://{INTERFACE_DB_HOST}:{INTERFACE_DB_PORT}/"

@app.route("/")
def home():
    try:
        response = requests.get(BASE_URL+"health/db")
        return f"Réponse de l'interface C#: {response.text}"
    except Exception as e:
        return f"Erreur lors de l'appel à interface_db: {e}"

@app.route("/init-db")
def init_db():
    try:
        response = requests.get(BASE_URL+"init/db")
        return f"Réponse de l'interface C#: {response.text}"
    except Exception as e:
        return f"Erreur lors de l'appel à interface_db: {e}"

@app.route("/upload-csv", methods=["POST"])
def upload_csv_chunk():
    data = request.get_json()
    if not data or "chunk" not in data:
        return jsonify({"error": "Aucun chunk reçu"}), 400

    lines = data["chunk"]

    return jsonify({"status": "ok", "received": len(lines)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
