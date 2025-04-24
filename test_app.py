import json
import pytest
from server.app import app, get_db_connection, release_db_connection

class DummyCursor:
    def __init__(self, results):
        self._results = results
    def __enter__(self): return self
    def __exit__(self, exc_type, exc, tb): pass
    def execute(self, query, params=None): pass
    def fetchone(self): return self._results.pop(0)
    def fetchall(self): return self._results

class DummyConnection:
    def __init__(self, cursor_results):
        self._cursor_results = cursor_results
    def cursor(self, cursor_factory=None):
        return DummyCursor(self._cursor_results)

@pytest.fixture(autouse=True)
def disable_db_pool(monkeypatch):
    # Prevent real DB pool interactions
    monkeypatch.setattr('server.app.release_db_connection', lambda conn: None)

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

# Login endpoint tests

def test_login_missing_json(client):
    resp = client.post('/api/login')
    assert resp.status_code == 400
    data = resp.get_json()
    assert data['error'] == 'Requête JSON attendue'


def test_login_missing_fields(client):
    resp = client.post('/api/login', json={})
    assert resp.status_code == 400
    data = resp.get_json()
    assert 'username et password requis' in data['error']


def test_login_db_error(monkeypatch, client):
    monkeypatch.setattr('server.app.get_db_connection', lambda: None)
    resp = client.post('/api/login', json={'username':'u','password':'p'})
    assert resp.status_code == 500
    data = resp.get_json()
    assert 'Erreur de connexion à la base de données' in data['error']


def test_login_invalid_credentials(monkeypatch, client):
    # Simulate no user found
    monkeypatch.setattr('server.app.get_db_connection', lambda: DummyConnection([None]))
    resp = client.post('/api/login', json={'username':'u','password':'p'})
    assert resp.status_code == 401
    data = resp.get_json()
    assert data['success'] is False


def test_login_success(monkeypatch, client):
    # Simulate valid user
    user = {'username':'u','password_hash':'p','user_type':'autre','phone':'123'}
    monkeypatch.setattr('server.app.get_db_connection', lambda: DummyConnection([user]))
    resp = client.post('/api/login', json={'username':'u','password':'p'})
    assert resp.status_code == 200
    data = resp.get_json()
    assert data['success'] is True
    assert data['user']['username'] == 'u'

# Houses endpoint tests

def test_get_houses_pagination(monkeypatch, client):
    houses = [{'id':1,'name':'h1','address':'a','user_count':1,'daily_energy':10}]
    monkeypatch.setattr('server.app.get_db_connection', lambda: DummyConnection([houses]))
    resp = client.get('/api/houses?page=1&per_page=1')
    assert resp.status_code == 200
    data = resp.get_json()
    assert isinstance(data, list)
    assert len(data) == 1
