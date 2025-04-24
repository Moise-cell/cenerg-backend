#!/usr/bin/env python3
# Standard imports
import os
from os import path
# Third-party imports
from dotenv import load_dotenv
from psycopg2 import pool

# Load .env from this script's directory
dotenv_path = path.join(path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

# Déterminer sslmode à partir de l'environnement
ssl_env = os.getenv('DB_SSLMODE') or os.getenv('DB_SSL')
if ssl_env:
    se = ssl_env.lower()
    if se in ('true', 'require'):
        sslmode = 'require'
    elif se in ('false', 'disable'):
        sslmode = 'disable'
    else:
        sslmode = ssl_env
else:
    sslmode = 'disable'

db_config = {
    'dbname': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT'),
    'sslmode': sslmode
}

db_pool = pool.SimpleConnectionPool(1, 10, **db_config)

def init_db():
    conn = db_pool.getconn()
    cur = conn.cursor()
    # Créer et utiliser le schéma de l'utilisateur (pour Neon éviter public)
    user_schema = os.getenv('DB_USER')
    if user_schema:
        cur.execute(f"CREATE SCHEMA IF NOT EXISTS {user_schema};")
        cur.execute(f"SET search_path TO {user_schema};")
    # Create houses table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS houses (
            id SERIAL PRIMARY KEY,
            energy_balance NUMERIC DEFAULT 0
        );
    """ )
    # Create phone_numbers table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS phone_numbers (
            maison1 TEXT,
            maison2 TEXT,
            proprietaire TEXT
        );
    """ )
    # Insert default row if none exists
    cur.execute("SELECT count(*) FROM phone_numbers;")
    if cur.fetchone()[0] == 0:
        cur.execute(
            "INSERT INTO phone_numbers (maison1, maison2, proprietaire) VALUES ('', '', '');"
        )
    conn.commit()
    cur.close()
    db_pool.putconn(conn)
    print("Database initialized.")

if __name__ == '__main__':
    init_db()
