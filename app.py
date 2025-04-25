from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import logging
from psycopg2 import pool
from dotenv import load_dotenv

# Charger les variables d'environnement depuis la racine du projet
load_dotenv()

app = Flask(__name__)
CORS(app)

# Configuration de la base de données
db_config = {
    'dbname': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT'),
    'sslmode': os.getenv('DB_SSLMODE', os.getenv('DB_SSL', 'require'))
}

# Normalize SSL mode from env vars
ssl_raw = os.getenv('DB_SSLMODE') or os.getenv('DB_SSL') or 'require'
ssl_lower = ssl_raw.strip().lower()
if ssl_lower in ('true', '1', 'yes'):
    sslmode_setting = 'require'
elif ssl_lower in ('false', '0', 'no'):
    sslmode_setting = 'disable'
else:
    sslmode_setting = ssl_lower

# Initialiser le pool de connexions
try:
    db_pool = pool.SimpleConnectionPool(
        1, 10,
        dbname=os.getenv('DB_NAME'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        host=os.getenv('DB_HOST'),
        port=os.getenv('DB_PORT'),
        sslmode=sslmode_setting
    )
except Exception as e:
    logging.warning(f"Could not initialize DB pool: {e}")
    db_pool = None

def get_db_connection():
    if not db_pool:
        return None
    return db_pool.getconn()

def release_db_connection(conn):
    if db_pool and conn:
        try:
            db_pool.putconn(conn)
        except Exception:
            # ignore release errors for dummy connections
            pass

@app.route('/')
@app.route('/health')
def home():
    return jsonify({
        'message': 'CenErg API is running',
        'endpoints': {
            'GET /health/users/phones': 'Get all phone numbers',
            'GET /health/houses/<house_id>/energy': 'Get house energy balance',
            'POST /health/houses/<house_id>/energy': 'Update house energy balance'
        }
    })

@app.route('/users/phones')
@app.route('/health/users/phones')
def get_phones():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Failed to get database connection'}), 500
        cur = conn.cursor()
        
        # Utiliser la vue que nous avons créée
        cur.execute('SELECT * FROM phone_numbers;')
        result = cur.fetchone()
        
        if result:
            phones = {
                'maison1': result[0],
                'maison2': result[1],
                'proprietaire': result[2]
            }
        else:
            phones = {
                'maison1': '',
                'maison2': '',
                'proprietaire': ''
            }
        
        cur.close()
        release_db_connection(conn)
        
        return jsonify(phones)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/houses/<house_id>/energy', methods=['GET'])
@app.route('/health/houses/<house_id>/energy', methods=['GET'])
def get_house_energy(house_id):
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Failed to get database connection'}), 500
        cur = conn.cursor()
        
        cur.execute('SELECT energy_balance FROM houses WHERE id = %s;', (house_id,))
        result = cur.fetchone()
        
        if result:
            energy = {
                'balance': float(result[0])
            }
        else:
            energy = {
                'balance': 0.0
            }
        
        cur.close()
        release_db_connection(conn)
        
        return jsonify(energy)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/houses/<house_id>/energy', methods=['POST'])
@app.route('/health/houses/<house_id>/energy', methods=['POST'])
def update_house_energy(house_id):
    try:
        data = request.get_json()
        if not data or 'amount' not in data:
            return jsonify({'error': 'amount is required'}), 400
            
        amount = float(data['amount'])
        
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Failed to get database connection'}), 500
        cur = conn.cursor()
        
        # Mettre à jour le solde d'énergie
        cur.execute('''
            UPDATE houses 
            SET energy_balance = energy_balance + %s 
            WHERE id = %s 
            RETURNING energy_balance;
        ''', (amount, house_id))
        
        result = cur.fetchone()
        conn.commit()
        
        if result:
            energy = {
                'balance': float(result[0])
            }
        else:
            energy = {
                'balance': 0.0
            }
        
        cur.close()
        release_db_connection(conn)
        
        return jsonify(energy)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json(silent=True)
    if data is None:
        return jsonify({'error': 'Requête JSON attendue'}), 400
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'username et password requis'}), 400
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Erreur de connexion à la base de données'}), 500
    cur = conn.cursor()
    cur.execute(
        'SELECT username, password_hash, user_type, phone FROM users WHERE username = %s',
        (username,)
    )
    user = cur.fetchone()
    if not user:
        return jsonify({'success': False}), 401
    if isinstance(user, dict):
        return jsonify({'success': True, 'user': user})
    return jsonify({
        'success': True,
        'user': {
            'username': user[0],
            'password_hash': user[1],
            'user_type': user[2],
            'phone': user[3]
        }
    })

@app.route('/api/houses', methods=['GET'])
def get_houses():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Failed to get database connection'}), 500
    cur = conn.cursor()
    cur.execute(
        'SELECT id, name, address, user_count, daily_energy '
        'FROM houses ORDER BY id LIMIT %s OFFSET %s',
        (per_page, (page-1)*per_page)
    )
    result = cur.fetchall()
    return jsonify(result)

if __name__ == '__main__':
    print('Starting CenErg API server...')
    app.run(host='0.0.0.0', port=int(os.getenv('API_PORT', 5000)), debug=True)
