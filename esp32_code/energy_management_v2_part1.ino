// Inclure les bibliothèques nécessaires
#include "env.h"
#include "wifi_manager.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>
#include <ZMPT101B.h>

// Instance du gestionnaire WiFi
WiFiManager wifiManager;

// Configuration LCD I2C
LiquidCrystal_I2C lcd(0x27, 20, 4);

// Configuration Keypad 4x4
const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS] = {13, 12, 14, 27};
byte colPins[COLS] = {26, 25, 33, 32};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// Configuration des broches
#define RELAY1_PIN 18        // Relais maison 1
#define RELAY2_PIN 19        // Relais maison 2
#define ACS712_1_PIN 34      // Capteur de courant maison 1
#define ACS712_2_PIN 35      // Capteur de courant maison 2
#define ZMPT101B_PIN 36      // Capteur de tension

// Structure pour stocker les numéros de téléphone
struct PhoneNumbers {
  char admin[15];    // Numéro du propriétaire
  char house1[15];   // Numéro maison 1
  char house2[15];   // Numéro maison 2
};

// Variables globales
PhoneNumbers phones;
float energy1 = 0.0;
float energy2 = 0.0;
float voltage = 0.0;
float current1 = 0.0;
float current2 = 0.0;
unsigned long lastMeasureTime = 0;
unsigned long lastWifiCheckTime = 0;
const unsigned long MEASURE_INTERVAL = 1000;    // 1 seconde
const unsigned long WIFI_CHECK_INTERVAL = 5000; // 5 secondes
bool relay1_state = true;
bool relay2_state = true;

// Objet ZMPT101B
ZMPT101B voltageSensor(ZMPT101B_PIN);

// États du menu
enum MenuState {
  MAIN_DISPLAY,
  RECHARGE_AMOUNT,
  CHANGE_PHONE,
  SELECT_HOUSE
};
MenuState currentState = MAIN_DISPLAY;
int selectedHouse = 0;
String inputBuffer = "";

void setup() {
  Serial.begin(115200);
  
  // Initialisation des broches
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(ACS712_1_PIN, INPUT);
  pinMode(ACS712_2_PIN, INPUT);
  pinMode(ZMPT101B_PIN, INPUT);

  // Initialisation de l'écran LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.print("Demarrage...");

  // Connexion au WiFi
  connectToWiFi();

  // Initialisation EEPROM
  EEPROM.begin(512);
  loadPhoneNumbers();
  
  // État initial des relais
  relay1_state = EEPROM.read(0) == 1;
  relay2_state = EEPROM.read(1) == 1;
  digitalWrite(RELAY1_PIN, relay1_state);
  digitalWrite(RELAY2_PIN, relay2_state);
  
  // Calibration du capteur de tension
  voltageSensor.calibrate();
  
  // Initialisation GSM
  initGSM();
  
  // Affichage initial
  updateDisplay();
}

void connectToWiFi() {
  lcd.clear();
  lcd.print("Connexion WiFi..");
  
  int attempts = 0;
  while (!wifiManager.connectToAnyNetwork() && attempts < 3) {
    lcd.clear();
    lcd.print("Tentative ");
    lcd.print(attempts + 1);
    lcd.setCursor(0, 1);
    lcd.print(wifiManager.getLastError());
    delay(2000);
    attempts++;
  }

  if (wifiManager.isConnected()) {
    lcd.clear();
    lcd.print("WiFi: ");
    lcd.print(wifiManager.getCurrentSSID());
  } else {
    lcd.clear();
    lcd.print("Erreur WiFi!");
    lcd.setCursor(0, 1);
    lcd.print("Mode hors ligne");
  }
}

void loop() {
  unsigned long currentTime = millis();

  // Vérification périodique du WiFi
  if (currentTime - lastWifiCheckTime >= WIFI_CHECK_INTERVAL) {
    if (!wifiManager.isConnected()) {
      connectToWiFi();
    }
    lastWifiCheckTime = currentTime;
  }

  // Maintenir la connexion WiFi
  wifiManager.maintainConnection();

  char key = keypad.getKey();
  if (key) {
    handleKeypad(key);
  }
  
  // Mesures périodiques
  if (currentTime - lastMeasureTime >= MEASURE_INTERVAL) {
    updateMeasurements();
    checkEnergyLevels();
    lastMeasureTime = currentTime;
  }
  
  // Vérification des SMS
  checkIncomingSMS();
}

void handleKeypad(char key) {
  switch(currentState) {
    case MAIN_DISPLAY:
      handleMainMenu(key);
      break;
    case RECHARGE_AMOUNT:
      handleRechargeInput(key);
      break;
    case CHANGE_PHONE:
      handlePhoneInput(key);
      break;
    case SELECT_HOUSE:
      handleHouseSelection(key);
      break;
  }
}

void handleMainMenu(char key) {
  switch(key) {
    case 'A': // Recharger maison 1
      selectedHouse = 1;
      currentState = RECHARGE_AMOUNT;
      inputBuffer = "";
      lcd.clear();
      lcd.print("Recharge Maison 1");
      lcd.setCursor(0, 1);
      lcd.print("Montant: ");
      break;
      
    case 'B': // Recharger maison 2
      selectedHouse = 2;
      currentState = RECHARGE_AMOUNT;
      inputBuffer = "";
      lcd.clear();
      lcd.print("Recharge Maison 2");
      lcd.setCursor(0, 1);
      lcd.print("Montant: ");
      break;
      
    case 'C': // Changer numéro de téléphone
      currentState = SELECT_HOUSE;
      lcd.clear();
      lcd.print("Changer numero:");
      lcd.setCursor(0, 1);
      lcd.print("1:M1 2:M2 3:Admin");
      break;
  }
}
