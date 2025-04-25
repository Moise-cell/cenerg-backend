-- Création de la table des maisons
CREATE TABLE houses (
    id SERIAL PRIMARY KEY,
    house_number INTEGER NOT NULL UNIQUE,
    remaining_energy DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    phone_number VARCHAR(15),
    last_update TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des recharges
CREATE TABLE energy_recharges (
    id SERIAL PRIMARY KEY,
    house_id INTEGER REFERENCES houses(id),
    amount DECIMAL(10, 2) NOT NULL,
    recharge_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des utilisateurs
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('proprietaire', 'house')),
    house_id INTEGER REFERENCES houses(id)
);

-- Création de la table des mesures énergétiques
CREATE TABLE energy_measurements (
    id SERIAL PRIMARY KEY,
    house_id INTEGER REFERENCES houses(id),
    current_value DECIMAL(10, 2) NOT NULL,
    voltage_value DECIMAL(10, 2) NOT NULL,
    power_consumption DECIMAL(10, 2) NOT NULL,
    measurement_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Création de la table des événements
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    house_id INTEGER REFERENCES houses(id),
    event_type VARCHAR(50) NOT NULL,
    description TEXT,
    event_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insertion des maisons initiales
INSERT INTO houses (house_number, remaining_energy, phone_number) VALUES 
(1, 0.0, '+33XXXXXXXXX'),
(2, 0.0, '+33XXXXXXXXX');

-- Insertion du compte propriétaire
INSERT INTO users (username, password_hash, user_type) VALUES 
('admin', 'votre_mot_de_passe_hashé', 'proprietaire');

-- Création des index pour optimiser les performances
CREATE INDEX idx_houses_number ON houses(house_number);
CREATE INDEX idx_recharges_house ON energy_recharges(house_id);
CREATE INDEX idx_measurements_house ON energy_measurements(house_id);
CREATE INDEX idx_events_house ON events(house_id);
CREATE INDEX idx_measurements_time ON energy_measurements(measurement_time);

-- Création d'un trigger pour mettre à jour last_update
CREATE OR REPLACE FUNCTION update_house_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER house_timestamp
    BEFORE UPDATE ON houses
    FOR EACH ROW
    EXECUTE FUNCTION update_house_timestamp();

-- Création d'une vue pour les statistiques
CREATE VIEW house_statistics AS
SELECT 
    h.house_number,
    h.remaining_energy,
    COUNT(er.id) as total_recharges,
    COALESCE(SUM(er.amount), 0) as total_recharged,
    MAX(em.power_consumption) as max_power,
    AVG(em.power_consumption) as avg_power
FROM houses h
LEFT JOIN energy_recharges er ON h.id = er.house_id
LEFT JOIN energy_measurements em ON h.id = em.house_id
GROUP BY h.id, h.house_number, h.remaining_energy;
