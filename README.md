[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/OrIXxyRw)
TP2
===

Ce dépôt contient le matériel nécessaire à la réalisation du second TP.

Ennoncé
=======

Vous travaillez pour une société du secteur bancaire à la réalisation d'un nouveau logiciel d'assistance au dépôt de chèques.

Ce logiciel va être décliné en différents supports : application mobile, site web, application pour smartwatch.

Dans le soucis de cette déclinaison, la décision est prise de créer une librairie de code partagé comportant la logique qui va permettre de convertir un nombre saisit par un utilisateur en une suite de lettres.

Votre rôle est d'implémenter cette partie du logiciel en utilisant les tests mis à dispositions par le chef de projet.

Vous avez à disposition une solution Visual Studio avec deux projets :

- Une librairie de code
- Un projet de tests unitaires

Les tests font foi : Vous ne **devez pas** modifier le code des *tests existants* (fichier `UnitTests.cs`), **uniquement** le code de la *librairie*. Vous êtes libre cependant d'ajouter de nouveaux tests si le besoin se fait ressentir.

Implémentez le code de la librairie de sorte qu'il soit conforme aux tests en place.

Le code devra être commenté et lisible : chaque méthode ne devra pas dépasser 15 lignes.

Chaque méthode ajoutée devra avoir le bon niveau d'accessibilité (`public`, `internal`, `protected`, `private`) au sein de la classe `Parser`.
