[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/r9EWrYlE)
TP - Jeu de la vie de Conway
============================

Ce dépôt contient le matériel nécessaire à la réalisation du TP.

Énoncé
======

Votre binôme vous a envoyé le code d'un projet à rendre, il s'agit d'une implémentation
du [jeu de la vie de Conway](https://fr.wikipedia.org/wiki/Jeu_de_la_vie) ([vidéo](https://www.youtube.com/watch?v=eMn43As24Bo)).

Problème : même si la solution compile, le code ne fonctionne pas.

Heureusement, un projet de tests unitaires était fourni avec le modèle de projet, et vous savez que les tests sont bons.

Vous avez à disposition une solution Visual Studio avec deux projets :

- Une librairie de code
- Un projet de tests unitaires

Les tests font foi : vous ne **devez pas** modifier le code des *tests existants*, **uniquement** le code de la
*librairie*. Vous êtes libre cependant d'ajouter de nouveaux tests si le besoin se fait ressentir.

Vous devez faire les actions suivantes :

- Localisez et corrigez le bug qui empêche le code de fonctionner à l'aide des tests existants.
- Re-découpez le constructeur de la classe `Board` de sorte qu'il tienne en plusieurs fonctions de moins de 15 lignes.
- Simplifiez fa fonction `DetermineNextLiveState` de la class `Cell` pour la rendre plus concise.
- Ajustez l'accessibilité des propriétés et méthodes pour que le code ne soit pas trop ouvert.
- On peut générer un plateau aléatoirement avec `Board.Randomize`, mais `Random` n'est pas prédictible. Avec les
  principes SOLID étudiés au semestre précédent, proposez une implémentation permettant de *tester* la génération
  aléatoire.
