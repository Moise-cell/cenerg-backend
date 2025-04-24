#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <WiFi.h>
#include "env.h"

class WiFiManager {
private:
    String current_ssid;
    IPAddress server_ip;
    String last_error;
    
    bool connectToNetwork(const char* ssid, const char* password) {
        WiFi.begin(ssid, password);
        unsigned long startTime = millis();
        
        while (WiFi.status() != WL_CONNECTED && 
               millis() - startTime < WIFI_CONNECT_TIMEOUT) {
            delay(WIFI_RETRY_DELAY);
        }
        
        if (WiFi.status() == WL_CONNECTED) {
            last_error = "";
            return true;
        }
        
        last_error = "Timeout de connexion";
        return false;
    }

public:
    WiFiManager() : server_ip(192, 168, 43, 1) {
        last_error = "";
    }

    bool connectToAnyNetwork() {
        WiFi.mode(WIFI_STA);
        WiFi.disconnect();
        delay(100);

        int n = WiFi.scanNetworks();
        if (n == 0) {
            last_error = "Aucun réseau trouvé";
            return false;
        }

        // Parcourir les réseaux trouvés
        for (int i = 0; i < n; i++) {
            String scanned_ssid = WiFi.SSID(i);
            
            // Vérifier si ce réseau est dans notre liste de réseaux connus
            for (int j = 0; j < MAX_NETWORKS && known_networks[j].ssid != NULL; j++) {
                if (scanned_ssid == known_networks[j].ssid) {
                    if (connectToNetwork(known_networks[j].ssid, known_networks[j].password)) {
                        current_ssid = scanned_ssid;
                        
                        // Configurer l'IP du serveur en fonction du réseau
                        if (scanned_ssid == "MoiseMb") {
                            server_ip = IPAddress(192, 168, 43, 1);
                        }
                        return true;
                    }
                }
            }
        }
        
        last_error = "Aucun réseau connu trouvé";
        return false;
    }

    void maintainConnection() {
        if (WiFi.status() != WL_CONNECTED) {
            if (!connectToAnyNetwork()) {
                delay(5000); // Attendre avant de réessayer
            }
        }
    }

    IPAddress getServerIP() {
        return server_ip;
    }

    String getCurrentSSID() {
        return current_ssid;
    }

    String getLastError() {
        return last_error;
    }

    bool isConnected() {
        return WiFi.status() == WL_CONNECTED;
    }

    void addNewNetwork(const char* ssid, const char* password) {
        for (int i = 0; i < MAX_NETWORKS; i++) {
            if (known_networks[i].ssid == NULL) {
                known_networks[i].ssid = ssid;
                known_networks[i].password = password;
                break;
            }
        }
    }
};

#endif // WIFI_MANAGER_H
