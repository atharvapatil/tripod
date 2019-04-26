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


// UUID to identify sensor one and commmunicate with it's charectersitcs
let SERVICE_LED_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214"
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
    
    
    @IBOutlet weak var buttonValue: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        buttonValue.text = "Connecting to Arduino"
    }


}


extension ViewController: CBCentralManagerDelegate{
    
    // Scanning for a Peripherial with a Unique accessory UUID. This id the arduino UUID
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [CBUUID(string: SERVICE_LED_UUID)], options: nil)
//            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            print("Scanning for peripherals")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

//        guard let peripheral = arduinoPeripheral else {
//            return
//        }
        print("Discovered peripheral", peripheral)
    

        arduinoPeripheral = peripheral
        
        
        centralManager?.connect(arduinoPeripheral!, options: nil)
//
        print("Connected peripheral", arduinoPeripheral!.name as Any)

        
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        guard let peripheral = arduinoPeripheral else {
//            return
//        }
//
//        arduinoPeripheral = peripheral
//        print("Connected to ", peripheral.name!)
//        print("Pairing State ", peripheral.state)
//        print("Connected UUID ", peripheral.identifier.uuidString)
        print("Connected peripheral", arduinoPeripheral!)
        
        peripheral.delegate = self
        
        peripheral.discoverServices([CBUUID(string: SERVICE_LED_UUID)])
//        peripheral.discoverServices(nil)


    }
    
}

extension ViewController: CBPeripheralDelegate{

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
    
        buttonValue.text = "Connection Successful"
        
        print("Discovered services:", peripheral.services!)
        
        guard let LEDService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_LED_UUID)
        }) else {
            return
        }


        ledService = LEDService
        
        
        print("LED Service UUID", ledService!.uuid)
        
        peripheral.discoverCharacteristics([CBUUID(string: LED_CHARACTERISTIC_UUID)], for: LEDService)
        peripheral.discoverCharacteristics([CBUUID(string: BUTTON_CHARACTERISTIC_UUID)], for: LEDService)
        
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        print("Charecteristics Discovered", service.characteristics!)
        
        guard let ledCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: LED_CHARACTERISTIC_UUID)
        }) else {
            return
        }
        
        charOne = ledCharecteristic
        
        print("LED Charecteristic info ", ledCharecteristic)
        
        guard let buttonCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: BUTTON_CHARACTERISTIC_UUID)
        }) else {
            return
        }
        
        charTwo = buttonCharecteristic
        
        print("Button Charecteristic info ", buttonCharecteristic)
        
        peripheral.setNotifyValue(true, for: buttonCharecteristic)
        
        
        buttonValue.text = "Place hand on button"
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = charTwo!.value else {
            return
        }
    
        buttonValue.text = "Pulse Data"
        
        let integerValue = data.int8Value()
        
        print("Button integer value", integerValue)
        
    }

}

extension Data {
    func int8Value() -> Int8 {
        return Int8(bitPattern: self[0])
    }
}
