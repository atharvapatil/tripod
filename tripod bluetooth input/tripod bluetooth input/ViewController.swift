//
//  ViewController.swift
//  tripod bluetooth input
//
//  Created by Atharva Patil on 25/04/2019.
//  Copyright © 2019 Atharva Patil. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation


// UUID to identify the arduino device which in this case is the same as the service
let SERVICE_LED_UUID = "4cc4513b-1b63-4c93-a419-dddaeae3fdc7"

// UUID's to identify the charecteristics of the sensors
let LED_CHARACTERISTIC_UUID = "ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4"
let BUTTON_CHARACTERISTIC_UUID = "db07a43f-07e3-4857-bccc-f01abfb8845c"

class ViewController: UIViewController {
    
    
    // DECLARING BLUETOOTH VARIABLES: BEGINS HERE
    
    // Initialising the Bluetooth manager object
    var centralManager: CBCentralManager?
    
    // Initialising Peripheral object which is responsible for discovering a nerby Accessory
    var arduinoPeripheral: CBPeripheral?
    
    // Variables to identify different sensors on the arduino as individual services which have chareteristics attached to them
    var ledService: CBService?
    
    // Variables to communicate the state of a charecteristic to and from the arduino
    var charOne: CBCharacteristic?
    var charTwo: CBCharacteristic?
    
    // DECLARING BLUETOOTH VARIABLES: ENDS HERE
    
    // label to appened states & the data incoming from the periphral
    @IBOutlet weak var buttonValue: UILabel!
    
    @IBOutlet weak var otherButton: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Initiating bluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Text values at different states.
        // When the view loads the device starts connecting to Arduino
        buttonValue.text = "Connecting to Arduino"
        
        // TO-DO: Write and alert check here to see if Bluetooth is on or not. If Bluetooth is off through a alert with message.
    }


}


extension ViewController: CBCentralManagerDelegate{
    
    // Scanning for a Peripherial with a Unique accessory UUID. This id the arduino UUID
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            
            // The commented statement below searches for all discoverable peripherals, turn on for testing
            // central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
            // Scanning for a specific UUID peripheral
            central.scanForPeripherals(withServices: [CBUUID(string: SERVICE_LED_UUID)], options: nil)
            
            // Logging to see of Bluetooth is scanning for the defined UUID peripheral
            print("Scanning for peripheral with UUID: ", SERVICE_LED_UUID)
            
        }
    }
    
    // This function handles the cases when the Bluetooth device we are looking for is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // If the peripheral is discovered log the details
        print("Discovered peripheral", peripheral)
    
        // Reference it
        arduinoPeripheral = peripheral
        
        // Connect to the Arduino peripheral
        centralManager?.connect(arduinoPeripheral!, options: nil)

        // print out the connection attempt
        print("Connecting to: ", arduinoPeripheral!)

    }
    
    // This function hadles the cases when the connection is successful
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       
        // Check if we are connected to the same peripheral
        guard let peripheral = arduinoPeripheral else {
            return
        }
        
        // Delegating
        peripheral.delegate = self
        
        // the connected peripheral's properties
        print("Connected to: ", arduinoPeripheral!)
        
        // Also the same feeback on the screen
        buttonValue.text = "Connection Successful"
        
        // Now that the device is connected start loooking for services attached to it.
        peripheral.discoverServices([CBUUID(string: SERVICE_LED_UUID)])
        
        // Test statement to discover all the services attached to the peripheral
        // peripheral.discoverServices(nil)

    }
    
}

// Now that is the a periphral discovered and referenced to start looking for properties attached to it.
extension ViewController: CBPeripheralDelegate{

    // This function handles the cases when there are services discovered for the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        
        // Logging the discovered services
        print("Discovered services:", peripheral.services!)
        
        // Feedback on screen
        buttonValue.text = "Services Discovered"
        
        // iterating through the services to retrive the one we are looking for
        guard let LEDService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_LED_UUID)
        }) else {
            return
        }
        
        // Referencing it
        ledService = LEDService
        
        // & Logging it's UUID to make sure it's the right one
        print("LED Service UUID", ledService!.uuid)
        
        // Now that the service is discovered and referenced to. Search for the charecteristics attached to it.
        peripheral.discoverCharacteristics([CBUUID(string: LED_CHARACTERISTIC_UUID)], for: LEDService)
        peripheral.discoverCharacteristics([CBUUID(string: BUTTON_CHARACTERISTIC_UUID)], for: LEDService)
        
    }

    // This function handles the cases when charecteristics are discovered(the ones we are looking for just above)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        // Log all the charecteristics for test
        // print("Charecteristics Discovered", service.characteristics!)
        
        // Look for a specific charecteristic
        guard let ledCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: LED_CHARACTERISTIC_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        charOne = ledCharecteristic
        
        // Log the properties of the charecteristic
        print("LED Charecteristic info ", ledCharecteristic)
        
        
        // Look for a specific charecteristic
        guard let buttonCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: BUTTON_CHARACTERISTIC_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        charTwo = buttonCharecteristic
        
        // Log the properties of the charecteristic
        print("Button Charecteristic info ", buttonCharecteristic)
        
        // If the propter can send/notify (BLENotify on arduino) then we need to reference a listener for it
        // This is the listenter event for that
        peripheral.setNotifyValue(true, for: buttonCharecteristic)
        peripheral.setNotifyValue(true, for: ledCharecteristic)
        
        // Now that the charectertistic is discovered it's time to press the button
        buttonValue.text = "Place hand on button"
        
    }
    
    // This function handles the cases when the sensor is sending some data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // SB Notes:
        // Return if there's an error
        if let error = error {
            print("Error receiving characteristic value:", error.localizedDescription)
            return
        }
        
        // As a best practice, you should grab the characteristic
        // that is passed here and do a check that it is the characteristic that you expect
        
        guard let updatedData = characteristic.value else {
            // It's also a good idea to print before returning so you can debug
            print("Unable to get data from characeristic:", characteristic)
            return
        }
        
        // Look into received bytes
        let byteArray = [UInt8](updatedData)
        print("Received:", byteArray)
//        print(byteArray, String(bytes: byteArray, encoding: .utf8)!)
        
        
        // Extract data from the charecteristic
        guard let data = charTwo!.value else {
            return
        }
        
        // Convert it to a human readable value
        let integerValue = data.int8Value()
        
        // Log that value
//        print("Button integer value", integerValue)
        
        if integerValue == 0{
            buttonValue.text = "First Button Pressed"
        } else {
            buttonValue.text = "First Button Released"
        }
        
        guard let dataTwo = charOne!.value else {
            return
        }


        let buttonTwoValue = dataTwo.int8Value()
//         let buttonTwoValue = [UInt8](dataTwo)
        
        otherButton.text = "Potentiometer input: " + "\(buttonTwoValue)"
        
//        if buttonTwoValue > 75{
//            otherButton.text = "Potentiometer > 75"
//        } else {
//            otherButton.text = "Potentiometer < 75"
//        }
        
//        print("Other Button integer value", buttonTwoValue)
        
        // Once I figured out how to convert byte data to String appened the data here.
//        buttonValue.text = "Pulse Data"
        
    }

}

// Functions to convert raw data to other formats
extension Data {
    func int8Value() -> Int8 {
        return Int8(bitPattern: self[0])
    }
    
}
