#ifndef FETCH_PHONES_H
#define FETCH_PHONES_H
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

struct Phones {
  char house1[15];
  char house2[15];
  char admin[15];
};

bool fetchPhones(Phones &phones, const char* api_url) {
  if (WiFi.status() != WL_CONNECTED) return false;
  HTTPClient http;
  http.begin(api_url);
  int httpCode = http.GET();
  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    DynamicJsonDocument doc(512);
    DeserializationError err = deserializeJson(doc, payload);
    if (err) return false;
    if (doc.containsKey("maison1")) strncpy(phones.house1, doc["maison1"], 14);
    if (doc.containsKey("maison2")) strncpy(phones.house2, doc["maison2"], 14);
    if (doc.containsKey("proprietaire")) strncpy(phones.admin, doc["proprietaire"], 14);
    phones.house1[14] = '\0';
    phones.house2[14] = '\0';
    phones.admin[14] = '\0';
    http.end();
    return true;
  }
  http.end();
  return false;
}

#endif // FETCH_PHONES_H
