# Automatisation

- Objectif du projet :

    Créer une interface permettant l'import de optimisé de logs en bdd depuis un fichier csv precis.


- Structure du projet :
```mermaid
flowchart LR
    Client -->|8080:80| IHM
    IHM -->|network_frontend-8081| Backend[traitement backend]

    Backend -->|network_backend-5000| InterfaceBDD[interface bdd]
    InterfaceBDD -->|network_bdd-5432| DB[(PostgreSQL)]
