-- Création des types énumérés
CREATE TYPE user_role AS ENUM ('admin', 'owner', 'resident');
CREATE TYPE sensor_type AS ENUM ('temperature', 'humidity', 'power', 'water', 'gas');
CREATE TYPE event_type AS ENUM ('alert', 'warning', 'info');

-- Table des utilisateurs
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(15),  -- Numéro de téléphone
    role user_role NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

-- Table des maisons
CREATE TABLE houses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone_number VARCHAR(15),  -- Numéro de téléphone
    energy_balance DECIMAL(10,2) DEFAULT 0.0,  -- Solde d'énergie en kWh
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(owner_id, name)
);

-- Table des résidents
CREATE TABLE house_residents (
    house_id UUID REFERENCES houses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (house_id, user_id)
);

-- Table des paramètres
CREATE TABLE settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    house_id UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(house_id, name)
);

-- Table des capteurs
CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    house_id UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type sensor_type NOT NULL,
    location VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_reading_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(house_id, name)
);

-- Table des relevés
CREATE TABLE readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    value DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des événements
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    house_id UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
    type event_type NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des planifications
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    house_id UUID NOT NULL REFERENCES houses(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    cron_expression VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    action_params JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(house_id, name)
);

-- Création des index
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_houses_owner ON houses(owner_id);
CREATE INDEX idx_houses_phone ON houses(phone_number);
CREATE INDEX idx_sensors_house ON sensors(house_id);
CREATE INDEX idx_readings_sensor ON readings(sensor_id);
CREATE INDEX idx_readings_timestamp ON readings(timestamp);
CREATE INDEX idx_events_house ON events(house_id);
CREATE INDEX idx_events_type ON events(type);
CREATE INDEX idx_schedules_house ON schedules(house_id);

-- Insertion des données initiales
INSERT INTO users (id, username, password_hash, email, phone_number, role, first_name, last_name) VALUES
(
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewfWxHrR/UQBp/Oa', -- mot de passe: admin123
    'admin@cenerg.com',
    '+243973581507',  -- Numéro du propriétaire
    'admin',
    'Admin',
    'System'
),
(
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    'owner1',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewfWxHrR/UQBp/Oa', -- mot de passe: owner123
    'owner1@cenerg.com',
    '+243973581507',  -- Même numéro que l'admin car c'est le propriétaire
    'owner',
    'Jean',
    'Dupont'
);

-- Insertion des maisons de test
INSERT INTO houses (id, name, address, owner_id, phone_number, energy_balance) VALUES
(
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
    'Maison 1',
    '123 Rue de la Paix, 75000 Paris',
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    '+243997795866',  -- Numéro de la maison 1
    100.0  -- Solde initial de 100 kWh
),
(
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    'Maison 2',
    '456 Avenue des Champs-Élysées, 75008 Paris',
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
    '+243974423496',  -- Numéro de la maison 2
    100.0  -- Solde initial de 100 kWh
);

-- Insertion des capteurs de test
INSERT INTO sensors (id, house_id, name, type, location) VALUES
(
    'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
    'Compteur Électrique',
    'power',
    'Entrée'
),
(
    'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a66',
    'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
    'Compteur Électrique',
    'power',
    'Entrée'
);

-- Création des triggers pour la mise à jour automatique des timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_houses_updated_at
    BEFORE UPDATE ON houses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedules_updated_at
    BEFORE UPDATE ON schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Création d'une vue pour les numéros de téléphone (format attendu par l'ESP32)
CREATE VIEW phone_numbers AS
SELECT 
    h.phone_number as maison1,
    h2.phone_number as maison2,
    u.phone_number as proprietaire
FROM houses h
CROSS JOIN houses h2
JOIN users u ON u.role = 'admin'
WHERE h.name = 'Maison 1'
AND h2.name = 'Maison 2'
LIMIT 1;
