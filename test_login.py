import requests

url = "https://cenerg-backend.onrender.com/api/login"
payload = {
    "username": "admin",
    "password": "admin123"
}

response = requests.post(url, json=payload)
print(response.status_code, response.text)
