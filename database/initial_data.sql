-- Création des maisons
INSERT INTO houses (id, name, address) VALUES
(uuid_generate_v4(), 'Maison 1', '123 Rue de la Paix'),
(uuid_generate_v4(), 'Maison 2', '456 Avenue des Fleurs');

-- Récupérer les IDs des maisons pour les utiliser dans les insertions suivantes
DO $$
DECLARE
    house1_id UUID;
    house2_id UUID;
BEGIN
    SELECT id INTO house1_id FROM houses WHERE name = 'Maison 1';
    SELECT id INTO house2_id FROM houses WHERE name = 'Maison 2';

    -- Création des paramètres pour chaque maison
    INSERT INTO house_settings 
    (house_id, temperature_min, temperature_max, humidity_min, humidity_max)
    VALUES
    (house1_id, 18.0, 22.0, 40, 60),
    (house2_id, 19.0, 23.0, 45, 65);

    -- Création des utilisateurs
    -- Note: Les mots de passe doivent être hashés dans l'application
    -- Ici nous utilisons des valeurs temporaires
    INSERT INTO users (username, password_hash, role, house_id) VALUES
    ('proprietaire', 'temporary_hash', 'owner', NULL),
    ('maison1', 'temporary_hash', 'house1', house1_id),
    ('maison2', 'temporary_hash', 'house2', house2_id);

    -- Création des capteurs pour chaque maison
    INSERT INTO sensors (house_id, name, type, location) VALUES
    (house1_id, 'Capteur Salon 1', 'temperature', 'Salon'),
    (house1_id, 'Capteur Chambre 1', 'temperature', 'Chambre'),
    (house2_id, 'Capteur Salon 2', 'temperature', 'Salon'),
    (house2_id, 'Capteur Chambre 2', 'temperature', 'Chambre');

END $$;
