
// Hardware used Arduino mkr 1010


#include <ArduinoBLE.h>

//const int ledPin = 0; // set ledPin to on-board LED
int ledPin = A6; // set ledPin to on-board LED
const int buttonPin = 1; // set buttonPin to digital pin 1
int potValue = 0;

BLEService ledService("4cc4513b-1b63-4c93-a419-dddaeae3fdc7"); // create service

// create switch characteristic and allow remote device to read and write
BLEByteCharacteristic ledCharacteristic("ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4", BLERead | BLENotify);
// create button characteristic and allow remote device to get notifications
BLEByteCharacteristic buttonCharacteristic("db07a43f-07e3-4857-bccc-f01abfb8845c", BLERead | BLENotify);

void setup() {
  Serial.begin(9600);
  while (!Serial);

  pinMode(ledPin, INPUT); // use the LED as an output
  pinMode(buttonPin, INPUT); // use button pin as an input

  // begin initialization
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");

    while (1);
  }

  // set the local name peripheral advertises
  BLE.setLocalName("ButtonLED");
  // set the UUID for the service this peripheral advertises:
  BLE.setAdvertisedService(ledService);

  // add the characteristics to the service
  ledService.addCharacteristic(ledCharacteristic);
  ledService.addCharacteristic(buttonCharacteristic);

  // add the service
  BLE.addService(ledService);

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

//   has the value changed since the last read
  boolean buttonChanged = (buttonCharacteristic.value() != buttonValue);

//  boolean buttonChanged = (buttonCharacteristic.value() == 1);


  if (buttonChanged) {
    // button state changed, update characteristics
//    ledCharacteristic.writeValue(buttonValue);
    buttonCharacteristic.writeValue(buttonValue);
    Serial.println("Button One interaction");
  }

//   if (buttonValue == LOW) {
//      Serial.println("LED on");
//      digitalWrite(ledPin, HIGH);
//    } else {
//      Serial.println("LED off");
//      digitalWrite(ledPin, LOW);
//    }

//  char buttonTwoValue = digitalRead(ledPin);

  int potValue = analogRead(ledPin);

  

  int mappedButtonTwoValue = map(potValue, 0, 1024, 0, 255);
  Serial.println(mappedButtonTwoValue);


  boolean buttonTwoChanged = (ledCharacteristic.value() != mappedButtonTwoValue);

   if (buttonTwoChanged) {
    // button state changed, update characteristics
    ledCharacteristic.writeValue(mappedButtonTwoValue);
//    buttonCharacteristic.writeValue(buttonValue);

//Serial.println(mappedButtonTwoValue);
  }

  
//  if (ledCharacteristic.written() || buttonChanged) {
//    // update LED, either central has written to characteristic or button state has changed
//    if (ledCharacteristic.value()) {
//      Serial.println("LED on");
//      digitalWrite(ledPin, HIGH);
//    } else {
//      Serial.println("LED off");
//      digitalWrite(ledPin, LOW);
//    }
//  }
}
