INSERT INTO users (username, password_hash, user_type, phone) VALUES
('proprietaire', 'test123', 'proprietaire', '+243973581507'),
('maison1', 'test123', 'maison', '+243997795866'),
('maison2', 'test123', 'maison', '+243974413496');-- Migration : Ajout d'un champ phone dans la table users
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Exemple d'update pour ajouter un numéro
-- UPDATE users SET phone = '+33612345678' WHERE username = 'maison1';
