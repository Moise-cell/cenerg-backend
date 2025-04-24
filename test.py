from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({
        'message': 'CenErg API is running',
        'status': 'OK'
    })

@app.route('/test')
def test():
    return jsonify({
        'maison1': '+243997795866',
        'maison2': '+243974423496',
        'proprietaire': '+243973581507'
    })

if __name__ == '__main__':
    print('Starting CenErg API server...')
    app.run(debug=True, host='0.0.0.0', port=5000)
