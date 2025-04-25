-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum pour les rôles utilisateur
CREATE TYPE user_role AS ENUM ('owner', 'house1', 'house2');

-- Table des utilisateurs
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    house_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_house_user CHECK (
        (role = 'owner' AND house_id IS NULL) OR
        (role IN ('house1', 'house2') AND house_id IS NOT NULL)
    )
);

-- Table des maisons
CREATE TABLE houses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des paramètres des maisons
CREATE TABLE house_settings (
    house_id UUID PRIMARY KEY REFERENCES houses(id),
    temperature_min DECIMAL(4,1),
    temperature_max DECIMAL(4,1),
    humidity_min INTEGER,
    humidity_max INTEGER,
    auto_mode BOOLEAN DEFAULT true,
    schedule_enabled BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des capteurs
CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    house_id UUID NOT NULL REFERENCES houses(id),
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL,
    location VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    last_reading_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des relevés de capteurs
CREATE TABLE sensor_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sensor_id UUID NOT NULL REFERENCES sensors(id),
    temperature DECIMAL(4,1),
    humidity INTEGER,
    battery_level INTEGER,
    rssi INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des événements
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    house_id UUID NOT NULL REFERENCES houses(id),
    type VARCHAR(50) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL,
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table des planifications
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    house_id UUID NOT NULL REFERENCES houses(id),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    temperature_target DECIMAL(4,1) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_time_range CHECK (start_time < end_time)
);

-- Index pour améliorer les performances
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_house_id ON users(house_id);
CREATE INDEX idx_sensors_house_id ON sensors(house_id);
CREATE INDEX idx_sensor_readings_sensor_id ON sensor_readings(sensor_id);
CREATE INDEX idx_sensor_readings_recorded_at ON sensor_readings(recorded_at);
CREATE INDEX idx_events_house_id ON events(house_id);
CREATE INDEX idx_events_created_at ON events(created_at);
CREATE INDEX idx_schedules_house_id ON schedules(house_id);

-- Trigger pour mettre à jour updated_at
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

CREATE TRIGGER update_house_settings_updated_at
    BEFORE UPDATE ON house_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Vues pour faciliter les requêtes courantes
CREATE VIEW v_house_latest_readings AS
SELECT 
    h.id AS house_id,
    h.name AS house_name,
    s.id AS sensor_id,
    s.name AS sensor_name,
    s.type AS sensor_type,
    sr.temperature,
    sr.humidity,
    sr.recorded_at
FROM houses h
JOIN sensors s ON s.house_id = h.id
LEFT JOIN LATERAL (
    SELECT temperature, humidity, recorded_at
    FROM sensor_readings
    WHERE sensor_id = s.id
    ORDER BY recorded_at DESC
    LIMIT 1
) sr ON true
WHERE h.is_active = true AND s.is_active = true;

-- Fonction pour obtenir les statistiques journalières
CREATE OR REPLACE FUNCTION get_daily_stats(
    p_house_id UUID,
    p_date DATE
)
RETURNS TABLE (
    avg_temperature DECIMAL(4,1),
    min_temperature DECIMAL(4,1),
    max_temperature DECIMAL(4,1),
    avg_humidity INTEGER,
    min_humidity INTEGER,
    max_humidity INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROUND(AVG(sr.temperature)::numeric, 1) as avg_temperature,
        MIN(sr.temperature) as min_temperature,
        MAX(sr.temperature) as max_temperature,
        ROUND(AVG(sr.humidity)::numeric) as avg_humidity,
        MIN(sr.humidity) as min_humidity,
        MAX(sr.humidity) as max_humidity
    FROM sensors s
    JOIN sensor_readings sr ON sr.sensor_id = s.id
    WHERE s.house_id = p_house_id
    AND DATE(sr.recorded_at) = p_date;
END;
$$ LANGUAGE plpgsql;
