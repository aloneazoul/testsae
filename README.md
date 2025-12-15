# Application de Gestion de Bibliothèque Universitaire

**Projet de conception et développement d'une application pour moderniser la gestion des prêts, des retours et des utilisateurs d'une bibliothèque universitaire.**

Le système actuel utilise des registres papier et des fichiers Excel, ce qui provoque des erreurs de suivi et une gestion inefficace des emprunts. L'objectif est de développer une application permettant d'améliorer la gestion des livres, des emprunts et des utilisateurs.

## Objectifs et Fonctionnalités

L'application doit intégrer les fonctionnalités suivantes :

### Gestion des Ressources
* **Gestion des Livres :** Permettre l'ajout, la modification, la suppression, la recherche et l'affichage des livres disponibles. Deux interfaces sont prévues : une page de recherche et une page de gestion.

* **Gestion des Emprunts et des Retours :** Assurer le suivi des prêts et des retours.
    * **Notifications de Retard :** Le système doit envoyer des rappels aux utilisateurs en cas de retard. Les rappels sont paramétrés à **J-30 et J-5** de l'échéance.

### Gestion des Utilisateurs et Sécurité
* **Authentification et Rôles :** Gérer différents rôles d'utilisateurs (bibliothécaire, étudiant, enseignant), avec des droits d'accès spécifiques.
* **Sécurisation :** Gestion des accès et sécurisation des données utilisateurs.

### Reporting
* **Tableau de Bord :** Affichage de statistiques sur l'utilisation de la bibliothèque (nombre d'emprunts, taux de retard, popularité des ouvrages, etc.). Cette fonctionnalité est réservée aux bibliothécaires.

### Interface
* **Interface Utilisateur :** L'interface doit être ergonomique et accessible via une interface web et/ou mobile.

## Contraintes Techniques

Le projet doit respecter les spécifications techniques suivantes :

* **Backend :** Développement en **Java ou Python ou C#**.
* **Base de Données :** Base de données relationnelle **MySQL**.
* **Frontend/Interface :** Interface utilisateur en **React.js ou ASPN.NET**.
* **Bonnes Pratiques :** Respect de la modularité, de la documentation et des tests unitaires.

## Instructions et Évaluation

### Livrables Attendus
1. **Code source** du projet sur un dépôt **Git** avec historique de commits.
2. **Rapport technique** décrivant l'architecture, les choix techniques et les tests réalisés.
3. **Démonstration** de l'application avec présentation des fonctionnalités développées.

### Critères d'Évaluation
Les étudiants seront évalués sur : 
* La qualité du code (maintenabilité, modularité, documentation).
* L'ergonomie et la performance de l'application.
* L'implémentation des fonctionnalités attendues.
* Les tests et la robustesse du système.
* L'utilisation d'un outil de gestion de version (Git) et l'organisation du projet en équipe.