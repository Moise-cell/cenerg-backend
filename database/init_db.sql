-- Création de la base de données
CREATE DATABASE cenerg;

-- Connexion à la base de données
\c cenerg

-- Création de la table des maisons
CREATE TABLE houses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des mesures d'énergie
CREATE TABLE energy_measurements (
    id SERIAL PRIMARY KEY,
    house_id INTEGER REFERENCES houses(id),
    voltage FLOAT NOT NULL,
    current1 FLOAT NOT NULL,
    current2 FLOAT NOT NULL,
    energy1 FLOAT NOT NULL,
    energy2 FLOAT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des utilisateurs
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des droits d'accès
CREATE TABLE house_access (
    user_id INTEGER REFERENCES users(id),
    house_id INTEGER REFERENCES houses(id),
    access_level VARCHAR(20) NOT NULL,
    PRIMARY KEY (user_id, house_id)
);

-- Création des index
CREATE INDEX idx_measurements_house_id ON energy_measurements(house_id);
CREATE INDEX idx_measurements_timestamp ON energy_measurements(timestamp);
CREATE INDEX idx_house_access_user ON house_access(user_id);

-- Création d'un utilisateur pour l'application
CREATE USER cenerg_app WITH PASSWORD 'votre_mot_de_passe_securise';
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO cenerg_app;
