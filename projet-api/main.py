from fastapi import FastAPI
from sqlalchemy import text
from pathlib import Path

import models
import database
from routers import auth, users, posts, friends, followers, trips, comments, stories, messages, interactions, notifications, map as map_router



app = FastAPI()

# Création des tables
models.Base.metadata.create_all(bind=database.engine)


def run_sql_file(path: Path):
    """
    Exécute un fichier SQL instruction par instruction (séparées par des ';'),
    compatible avec MySQL (qui n'aime pas les multi-statements en un seul execute()).
    """
    if not path.exists():
        print(f"⚠️ Fichier SQL introuvable : {path}")
        return

    sql_content = path.read_text(encoding="utf-8")

    # On coupe sur les ';' et on exécute chaque statement séparément
    statements = [s.strip() for s in sql_content.split(";") if s.strip()]

    with database.engine.begin() as conn:  # begin() = ouvre une transaction et commit automatique à la fin
        for stmt in statements:
            try:
                print(f"▶️ Exécution SQL : {stmt[:80]}{'...' if len(stmt) > 80 else ''}")
                conn.execute(text(stmt))
            except Exception as e:
                # On log l'erreur mais on ne casse pas tout si un index existe déjà, etc.
                print("⚠️ Erreur lors de l'exécution de :")
                print(stmt)
                print("Erreur :", e)


# 1) Indexes
INIT_INDEXES_PATH = Path(__file__).parent / "init_indexes.sql"
run_sql_file(INIT_INDEXES_PATH)

# 2) Données de base (pays, etc.) → seulement si pas encore remplies
INIT_DATA_PATH = Path(__file__).parent / "init_data.sql"

with database.engine.connect() as conn:
    result = conn.execute(text("SELECT COUNT(*) FROM countries"))
    count = result.scalar()

if count == 0:
    print("➡️ Aucune donnée pays trouvée, exécution de init_data.sql")
    run_sql_file(INIT_DATA_PATH)
else:
    print(f"✔️ {count} pays déjà présents, on ne relance pas init_data.sql")

# 3) Triggers
INIT_TRIGGERS_PATH = Path(__file__).parent / "init_triggers.sql"
run_sql_file(INIT_TRIGGERS_PATH)


# 4) Events
INIT_EVENTS_PATH = Path(__file__).parent / "init_events.sql"
run_sql_file(INIT_EVENTS_PATH)




app.include_router(auth.router)
app.include_router(users.router)
app.include_router(posts.router)
app.include_router(friends.router)
app.include_router(followers.router)
app.include_router(trips.router)
app.include_router(comments.router)
app.include_router(stories.router)
app.include_router(messages.router)
app.include_router(interactions.router)
app.include_router(notifications.router)
app.include_router(map_router.router)


@app.get("/")
def root():
    return {"message": "API en ligne 🚀"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8001)
