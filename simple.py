from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return {
        'message': 'CenErg API is running',
        'status': 'OK'
    }

@app.route('/test')
def test():
    return {
        'maison1': '+243997795866',
        'maison2': '+243974423496',
        'proprietaire': '+243973581507'
    }

if __name__ == '__main__':
    print('Starting CenErg API server...')
    app.run(host='localhost', port=5000)
