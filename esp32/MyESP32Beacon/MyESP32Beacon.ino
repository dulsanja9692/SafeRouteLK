#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// =========================
// PIN CONFIGURATION
// =========================
#define BUZZER 25

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

// =========================
// OLED
// =========================
Adafruit_SSD1306 display(
  SCREEN_WIDTH,
  SCREEN_HEIGHT,
  &Wire,
  -1
);

// =========================
// BLE
// =========================
BLECharacteristic *pCharacteristic;

// Modes: SAFE / MEDIUM / ALERT
String statusMode = "SAFE";

// =========================
// BLE CALLBACK
// =========================
class MyCallbacks : public BLECharacteristicCallbacks {

  void onWrite(BLECharacteristic *pChar) {

    String value = pChar->getValue();

    if (value == "ALERT") {
      statusMode = "ALERT";
    }

    else if (value == "MEDIUM") {
      statusMode = "MEDIUM";
      digitalWrite(BUZZER, LOW);
    }

    else if (value == "STOP") {
      statusMode = "SAFE";
      digitalWrite(BUZZER, LOW);
    }
  }
};

// =========================
// SETUP
// =========================
void setup() {

  Serial.begin(115200);

  // Buzzer
  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, LOW);

  // =========================
  // OLED INITIALIZATION
  // =========================
  Wire.begin(21, 22);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {

    Serial.println("OLED not found");

    for (;;);
  }

  display.clearDisplay();
  display.setTextColor(WHITE);

  display.setTextSize(1);
  display.setCursor(0, 10);

  display.println("Beacon System");
  display.println("Starting...");

  display.display();

  // =========================
  // BLE INITIALIZATION
  // =========================
  BLEDevice::init("MyESP32Beacon");

  BLEServer *pServer = BLEDevice::createServer();

  BLEService *pService =
    pServer->createService("1234");

  pCharacteristic =
    pService->createCharacteristic(
      "5678",
      BLECharacteristic::PROPERTY_WRITE
    );

  pCharacteristic->setCallbacks(
    new MyCallbacks()
  );

  pService->start();

  BLEAdvertising *pAdvertising =
    BLEDevice::getAdvertising();

  pAdvertising->start();

  Serial.println("Ready...");
}

// =========================
// LOOP
// =========================
void loop() {

  // =========================
  // ALERT STATE
  // =========================
  if (statusMode == "ALERT") {

    digitalWrite(BUZZER, HIGH);

    delay(500);

    digitalWrite(BUZZER, LOW);

    delay(150);

    display.clearDisplay();

    // Flash effect
    display.invertDisplay(true);

    display.drawRect(
      0,
      0,
      128,
      64,
      WHITE
    );

    display.setTextSize(3);
    display.setCursor(5, 0);

    display.println("ALERT!");

    display.setTextSize(1);
    display.setCursor(25, 48);

    display.println("Out of Range");

    display.display();

    delay(150);

    display.invertDisplay(false);
  }

  // =========================
  // MEDIUM STATE
  // =========================
  else if (statusMode == "MEDIUM") {

    digitalWrite(BUZZER, LOW);

    display.clearDisplay();

    display.drawRect(
      0,
      0,
      128,
      64,
      WHITE
    );

    display.setTextSize(2);
    display.setCursor(10, 5);

    display.println("CAUTION");

    display.setTextSize(1);
    display.setCursor(15, 40);

    display.println("Moving away");

    display.display();

    delay(200);
  }

  // =========================
  // SAFE STATE
  // =========================
  else {

    digitalWrite(BUZZER, LOW);

    display.clearDisplay();

    display.setTextSize(3);
    display.setCursor(15, 10);

    display.println("SAFE");

    display.setTextSize(1);
    display.setCursor(30, 45);

    display.println("All good");

    display.display();

    delay(200);
  }
}
