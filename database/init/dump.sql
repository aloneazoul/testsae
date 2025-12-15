CREATE DATABASE IF NOT EXISTS bibliotheque_db;
USE bibliotheque_db;

-- Création de la table Utilisateurs
CREATE TABLE Utilisateurs (
    id_utilisateur INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    role ENUM('etudiant', 'enseignant', 'bibliothecaire') NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table Livres
CREATE TABLE Livres (
    id_livre INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(13) UNIQUE,
    titre VARCHAR(255) NOT NULL,
    auteur VARCHAR(255),
    editeur VARCHAR(100),
    annee_publication YEAR,
    categorie VARCHAR(100)
);

-- Création de la table Exemplaires
CREATE TABLE Exemplaires (
    id_exemplaire INT AUTO_INCREMENT PRIMARY KEY,
    id_livre INT NOT NULL,
    code_barre VARCHAR(100) UNIQUE,
    statut_exemplaire ENUM('disponible', 'emprunte', 'perdu') NOT NULL DEFAULT 'disponible',
    etat_physique VARCHAR(255),
    FOREIGN KEY (id_livre) REFERENCES Livres(id_livre) ON DELETE CASCADE
);

-- Création de la table Emprunts
CREATE TABLE Emprunts (
    id_emprunt INT AUTO_INCREMENT PRIMARY KEY,
    id_exemplaire INT NOT NULL,
    id_utilisateur INT NOT NULL,
    date_emprunt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_retour_prevue DATE NOT NULL,
    date_retour_reelle DATETIME NULL,
    statut_emprunt ENUM('en_cours', 'termine', 'en_retard') NOT NULL DEFAULT 'en_cours',
    FOREIGN KEY (id_exemplaire) REFERENCES Exemplaires(id_exemplaire),
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateurs(id_utilisateur)
);


-- JEU DE DONNÉES DE TEST
USE bibliotheque_db;

INSERT INTO Utilisateurs (nom, prenom, email, mot_de_passe, role) VALUES 
('Dupont', 'Alice', 'alice.dupont@univ.fr', '1234', 'etudiant'),
('Martin', 'Bob', 'bob.martin@univ.fr', '1234', 'enseignant'),
('Admin', 'Charlie', 'admin@biblio.fr', '1234', 'bibliothecaire');

INSERT INTO Livres (isbn, titre, auteur, editeur, annee_publication, categorie) VALUES 
('978-2070368228', '1984', 'George Orwell', 'Gallimard', 1949, 'Science-Fiction'),
('978-2253004226', 'Le Petit Prince', 'Antoine de Saint-Exupéry', 'Folio', 1943, 'Jeunesse'),
('978-2081219229', 'Le Seigneur des Anneaux', 'J.R.R. Tolkien', 'Pocket', 1954, 'Fantasy'),
('978-2744070007', 'Apprendre Java', 'Cyril Delm', 'Eyrolles', 2023, 'Informatique'),
('978-0131103627', 'The C Programming Language', 'Brian Kernighan', 'Prentice Hall', 1988, 'Informatique');


INSERT INTO Exemplaires (id_livre, code_barre, statut_exemplaire, etat_physique) VALUES 
(1, 'CB-1984-01', 'disponible', 'neuf'),      -- Exemplaire de 1984
(1, 'CB-1984-02', 'emprunte', 'bon'),         -- Autre exemplaire de 1984
(4, 'CB-JAVA-01', 'disponible', 'abime'),     -- Exemplaire de Java
(4, 'CB-JAVA-02', 'perdu', 'moyen'),          -- Java perdu
(2, 'CB-PRINCE-01', 'emprunte', 'neuf');      -- Petit Prince


INSERT INTO Emprunts (id_exemplaire, id_utilisateur, date_emprunt, date_retour_prevue, date_retour_reelle, statut_emprunt) VALUES 
(1, 1, '2023-10-01 10:00:00', '2023-10-15', '2023-10-14 14:00:00', 'termine');

INSERT INTO Emprunts (id_exemplaire, id_utilisateur, date_emprunt, date_retour_prevue, statut_emprunt) VALUES 
(5, 1, NOW(), DATE_ADD(NOW(), INTERVAL 14 DAY), 'en_cours');
INSERT INTO Emprunts (id_exemplaire, id_utilisateur, date_emprunt, date_retour_prevue, statut_emprunt) VALUES 
(2, 2, '2023-01-01 09:00:00', '2023-01-15', 'en_retard');