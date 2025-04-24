from flask import Flask, jsonify, request
from flask_cors import CORS
import os
from pathlib import Path
from psycopg2 import pool
from dotenv import load_dotenv

# Charger les variables d'environnement depuis la racine du projet
basedir = Path(__file__).resolve().parent.parent
load_dotenv(basedir / '.env')

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

# Initialiser le pool de connexions
db_pool = pool.SimpleConnectionPool(
    1, 10,
    dbname=os.getenv('DB_NAME'),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    host=os.getenv('DB_HOST'),
    port=os.getenv('DB_PORT'),
    sslmode=os.getenv('DB_SSLMODE', os.getenv('DB_SSL', 'require'))
)

def get_db_connection():
    return db_pool.getconn()

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
        db_pool.putconn(conn)
        
        return jsonify(phones)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/houses/<house_id>/energy', methods=['GET'])
@app.route('/health/houses/<house_id>/energy', methods=['GET'])
def get_house_energy(house_id):
    try:
        conn = get_db_connection()
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
        db_pool.putconn(conn)
        
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
        db_pool.putconn(conn)
        
        return jsonify(energy)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print('Starting CenErg API server...')
    app.run(host='0.0.0.0', port=int(os.getenv('API_PORT', 5000)), debug=True)
