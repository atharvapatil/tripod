#include <ArduinoBLE.h>

const int ledPin = LED_BUILTIN; // set ledPin to on-board LED
const int buttonPin = 4; // set buttonPin to digital pin 4

BLEService tripodService("19B10010-E8F2-537E-4F6C-D104768A1214"); // create peripheral service

BLEService ledService("a350c7b9-a466-4550-848c-77e1aa16a72e"); // create led service
BLEService buttonService("43d34c21-ec24-4de8-98af-4faa86b279eb"); // create button service


// create switch characteristic and allow remote device to read and write
BLEByteCharacteristic ledCharacteristic("ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4", BLERead | BLEWrite);
// create button characteristic and allow remote device to get notifications
BLEByteCharacteristic buttonCharacteristic("db07a43f-07e3-4857-bccc-f01abfb8845c", BLERead | BLENotify);

void setup() {
  Serial.begin(9600);
  while (!Serial);

  pinMode(ledPin, OUTPUT); // use the LED as an output
  pinMode(buttonPin, INPUT); // use button pin as an input

  // begin initialization
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");

    while (1);
  }

  // set the local name peripheral advertises
  BLE.setLocalName("tripod");
  // set the UUID for the service this peripheral advertises:
  BLE.setAdvertisedService(tripodService);

  // add the service
//  BLE.addService(tripodService);
  BLE.addService(ledService);
  BLE.addService(buttonService);

  // add the characteristics to the service
  ledService.addCharacteristic(ledCharacteristic);
  buttonService.addCharacteristic(buttonCharacteristic);

  ledCharacteristic.writeValue(0);
  buttonCharacteristic.writeValue(0);

  // start advertising
  BLE.advertise();

  Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() {
  // poll for BLE events
  BLE.poll();

  // read the current button pin state
  char buttonValue = digitalRead(buttonPin);

  // has the value changed since the last read
  boolean buttonChanged = (buttonCharacteristic.value() != buttonValue);

  if (buttonChanged) {
    // button state changed, update characteristics
    ledCharacteristic.writeValue(buttonValue);
    buttonCharacteristic.writeValue(buttonValue);
  }

  if (ledCharacteristic.written() || buttonChanged) {
    // update LED, either central has written to characteristic or button state has changed
    if (ledCharacteristic.value()) {
      Serial.println("LED on");
      digitalWrite(ledPin, HIGH);
    } else {
      Serial.println("LED off");
      digitalWrite(ledPin, LOW);
    }
  }
}
