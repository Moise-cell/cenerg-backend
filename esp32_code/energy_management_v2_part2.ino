#include "fetch_phones.h"

Phones phones;

void setup() {
  Serial.begin(115200);
  
  // Initialisation du WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connecté");

  // Récupération des numéros depuis l'API Flask
  if (fetchPhones(phones, "http://<IP_SERVEUR_FLASK>:<PORT>/users/phones")) {
    Serial.println("Numéros récupérés depuis l'API");
  } else {
    Serial.println("Erreur lors du fetch des numéros");
    // Optionnel: valeurs par défaut
    strcpy(phones.house1, "+33XXXXXXXXX");
    strcpy(phones.house2, "+33XXXXXXXXX");
    strcpy(phones.admin, "+33XXXXXXXXX");
  }

  // Initialisation des broches
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(VOLTAGE_PIN, INPUT);
  pinMode(CURRENT1_PIN, INPUT);
  pinMode(CURRENT2_PIN, INPUT);

  // Initialisation de l'écran LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("Système démarré");

  // Chargement des états des relais depuis EEPROM
  EEPROM.begin(512);
  relay1_state = EEPROM.read(0) == 1;
  relay2_state = EEPROM.read(1) == 1;
  digitalWrite(RELAY1_PIN, relay1_state);
  digitalWrite(RELAY2_PIN, relay2_state);
}


void loop() {
  unsigned long currentTime = millis();

  // Mesure toutes les secondes
  if (currentTime - lastMeasureTime >= MEASURE_INTERVAL) {
    updateMeasurements();
    lastMeasureTime = currentTime;
    updateDisplay();
  }

  // Vérification des commandes WiFi
  checkWiFiCommands();
  
  // Lecture du clavier
  char key = keypad.getKey();
  if (key) {
    handleKeypad(key);
  }
}

void checkWiFiCommands() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(SERVER_URL "/commands");
    int httpCode = http.GET();
    
    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      DynamicJsonDocument doc(1024);
      deserializeJson(doc, payload);
      
      if (doc.containsKey("relay1")) {
        relay1_state = doc["relay1"].as<bool>();
        digitalWrite(RELAY1_PIN, relay1_state);
        EEPROM.write(0, relay1_state);
        // Suppression du commit EEPROM pour les numéros

      }
      
      if (doc.containsKey("relay2")) {
        relay2_state = doc["relay2"].as<bool>();
        digitalWrite(RELAY2_PIN, relay2_state);
        EEPROM.write(1, relay2_state);
        // Suppression du commit EEPROM pour les numéros

      }
    }
    
    http.end();
  }
}

void handleRechargeInput(char key) {
  if (key >= '0' && key <= '9') {
    if (inputBuffer.length() < 5) {
      inputBuffer += key;
      lcd.setCursor(9, 1);
      lcd.print(inputBuffer);
    }
  }
  else if (key == '#') { // Confirmer
    float amount = inputBuffer.toFloat();
    rechargeEnergy(selectedHouse, amount);
    currentState = MAIN_DISPLAY;
    updateDisplay();
  }
  else if (key == 'D') { // Annuler
    currentState = MAIN_DISPLAY;
    updateDisplay();
  }
}

// Suppression de la saisie et du stockage local des numéros de téléphone

void handleHouseSelection(char key) {
  if (key >= '1' && key <= '3') {
    selectedHouse = key - '0';
    currentState = CHANGE_PHONE;
    inputBuffer = "";
    lcd.clear();
    lcd.print("Nouveau numero:");
    if (selectedHouse == 1) lcd.print(" M1");
    else if (selectedHouse == 2) lcd.print(" M2");
    else lcd.print(" Admin");
  }
  else if (key == 'D') {
    currentState = MAIN_DISPLAY;
    updateDisplay();
  }
}

void updateMeasurements() {
  // Lecture de la tension
  voltage = voltageSensor.getVoltageAC();
  
  // Lecture des courants (avec calibration)
  float raw1 = analogRead(ACS712_1_PIN);
  float raw2 = analogRead(ACS712_2_PIN);
  current1 = ((raw1 - 1650) * 5.0 / 4096.0) / 0.185; // Pour ACS712-30A
  current2 = ((raw2 - 1650) * 5.0 / 4096.0) / 0.185;
  
  // Calcul de l'énergie consommée
  if (relay1_state) {
    float power1 = voltage * current1;
    energy1 -= (power1 * MEASURE_INTERVAL) / (3600.0 * 1000.0); // Conversion en kWh
  }
  
  if (relay2_state) {
    float power2 = voltage * current2;
    energy2 -= (power2 * MEASURE_INTERVAL) / (3600.0 * 1000.0);
  }
  
  if (currentState == MAIN_DISPLAY) {
    updateDisplay();
  }
}

void checkEnergyLevels() {
  // Vérification maison 1
  if (energy1 <= 0 && relay1_state) {
    energy1 = 0;
    relay1_state = false;
    digitalWrite(RELAY1_PIN, LOW);
    sendSMS(phones.admin, "ALERTE: Energie epuisee Maison 1");
    sendSMS(phones.house1, "Votre energie est epuisee. Contactez le proprietaire.");
  }
  
  // Vérification maison 2
  if (energy2 <= 0 && relay2_state) {
    energy2 = 0;
    relay2_state = false;
    digitalWrite(RELAY2_PIN, LOW);
    sendSMS(phones.admin, "ALERTE: Energie epuisee Maison 2");
    sendSMS(phones.house2, "Votre energie est epuisee. Contactez le proprietaire.");
  }
}

void rechargeEnergy(int house, float amount) {
  if (house == 1) {
    energy1 += amount;
    if (energy1 > 0 && !relay1_state) {
      relay1_state = true;
      digitalWrite(RELAY1_PIN, HIGH);
    }
    sendSMS(phones.house1, "Votre compte a ete recharge de " + String(amount) + " kWh");
    sendSMS(phones.admin, "Recharge M1: " + String(amount) + " kWh effectuee");
  }
  else if (house == 2) {
    energy2 += amount;
    if (energy2 > 0 && !relay2_state) {
      relay2_state = true;
      digitalWrite(RELAY2_PIN, HIGH);
    }
    sendSMS(phones.house2, "Votre compte a ete recharge de " + String(amount) + " kWh");
    sendSMS(phones.admin, "Recharge M2: " + String(amount) + " kWh effectuee");
  }
}

void updateDisplay() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("M1:");
  lcd.print(energy1, 1);
  lcd.print("kWh ");
  lcd.print(current1, 1);
  lcd.print("A");
  
  lcd.setCursor(0, 1);
  lcd.print("M2:");
  lcd.print(energy2, 1);
  lcd.print("kWh ");
  lcd.print(current2, 1);
  lcd.print("A");
  
  lcd.setCursor(0, 2);
  lcd.print("V:");
  lcd.print(voltage, 0);
  lcd.print("V");
  
  lcd.setCursor(0, 3);
  lcd.print("A:M1 B:M2 C:Config");
}

void checkIncomingSMS() {
  if (Serial2.available()) {
    String msg = Serial2.readString();
    if (msg.indexOf("+CMT:") >= 0) {
      String sender = extractPhone(msg);
      String content = extractContent(msg);
      processSMS(sender, content);
    }
  }
}

void processSMS(String sender, String content) {
  content.trim();
  content.toUpperCase();
  
  // Vérification si c'est le propriétaire
  if (sender == String(phones.admin)) {
    if (content.startsWith("RECHARGE")) {
      // Format: RECHARGE,maison,montant
      int comma1 = content.indexOf(',');
      int comma2 = content.indexOf(',', comma1 + 1);
      if (comma1 > 0 && comma2 > 0) {
        int house = content.substring(comma1 + 1, comma2).toInt();
        float amount = content.substring(comma2 + 1).toFloat();
        if (house == 1 || house == 2) {
          rechargeEnergy(house, amount);
        }
      }
    }
  }
  // Vérification si c'est une maison qui demande son solde
  else if (sender == String(phones.house1) && content == "SOLDE") {
    sendSMS(phones.house1, "Votre solde: " + String(energy1, 1) + " kWh");
  }
  else if (sender == String(phones.house2) && content == "SOLDE") {
    sendSMS(phones.house2, "Votre solde: " + String(energy2, 1) + " kWh");
  }
}

void initGSM() {
  Serial2.println("AT");
  delay(1000);
  Serial2.println("AT+CMGF=1"); // Mode texte
  delay(1000);
  Serial2.println("AT+CNMI=2,2,0,0,0"); // Notification des nouveaux SMS
  delay(1000);
}

void sendSMS(const char* number, String message) {
  Serial2.println("AT+CMGS=\"" + String(number) + "\"");
  delay(1000);
  Serial2.print(message);
  delay(100);
  Serial2.write(26); // Ctrl+Z pour envoyer
  delay(1000);
}

// Suppression de la fonction de chargement des numéros depuis l'EEPROM

  // Suppression de la lecture des numéros depuis l'EEPROM

  // Si c'est la première utilisation, initialiser avec des valeurs par défaut
  if (phones.admin[0] == 255) {
    strcpy(phones.admin, "+33XXXXXXXXX");
    strcpy(phones.house1, "+33XXXXXXXXX");
    strcpy(phones.house2, "+33XXXXXXXXX");
    savePhoneNumbers();
  }
}

// Suppression de la fonction de sauvegarde des numéros dans l'EEPROM

  // Suppression de l'écriture des numéros dans l'EEPROM

  // Suppression du commit EEPROM pour les numéros

}

String extractPhone(String msg) {
  int start = msg.indexOf("+CMT: \"") + 7;
  int end = msg.indexOf("\"", start);
  return msg.substring(start, end);
}

String extractContent(String msg) {
  int start = msg.lastIndexOf("\n") + 1;
  return msg.substring(start);
}
