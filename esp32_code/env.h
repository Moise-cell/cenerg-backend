#ifndef ENV_H
#define ENV_H

// Configuration des points d'accès WiFi connus
#define MAX_NETWORKS 5  // Nombre maximum de réseaux à mémoriser

struct WifiNetwork {
    const char* ssid;
    const char* password;
};

// Liste des réseaux connus
const WifiNetwork known_networks[MAX_NETWORKS] = {
    {"MoiseMb", "moise123"},        // Votre point d'accès principal
    {"Wifi_Bureau", "password2"},   // Exemple point d'accès bureau
    {"Wifi_Maison", "password3"},   // Exemple point d'accès maison
    {NULL, NULL},                   // Emplacement pour futur réseau
    {NULL, NULL}                    // Emplacement pour futur réseau
};

// Configuration Serveur
#define DEFAULT_SERVER_IP "192.168.43.1"  // IP par défaut (point d'accès mobile)
#define SERVER_PORT 5000                  // Port de l'API
#define SERVER_URL "https://cenerg-backend.onrender.com"

// Configuration des broches ESP32
#define RELAY1_PIN 26
#define RELAY2_PIN 27
#define VOLTAGE_PIN 34
#define CURRENT1_PIN 35
#define CURRENT2_PIN 36

// Configuration WiFi
#define WIFI_CONNECT_TIMEOUT 10000  // Timeout de connexion en millisecondes
#define WIFI_RETRY_DELAY 500        // Délai entre les tentatives en millisecondes

#endif // ENV_H
