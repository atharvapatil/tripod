//
//  ViewController.swift
//  tripod test
//
//  Created by Atharva Patil on 21/04/2019.
//  Copyright © 2019 Atharva Patil. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

// UUID to connect to the the Arduino mkr 1010
let ACCESSORY_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214"

// UUID to identify sensor one and commmunicate with it's charectersitcs
let SERVICE_ONE_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214"
let SERVICE_ONE_CHARACTERISTIC_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214"

// UUID to identify sensor two and commmunicate with it's charectersitcs
let SERVICE_TWO_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214"
let SERVICE_TWO_CHARACTERISTIC_UUID = "19B10010-E8F2-537E-4F6C-D104768A1214"


class ViewController: UIViewController{
    
    // DECLARING BLUETOOTH VARIABLES: BEGINS HERE
    
    // Initialising the Bluetooth manager object
    var centralManager: CBCentralManager?
    
    // Initialising Peripheral object which is responsible for discovering a nerby Accessory
    var arduinoPeripheral: CBPeripheral?

    // Variables to identify different sensors on the arduino as individual services which have chareteristics attached to them
    var serviceOne: CBService?
    var serviceTwo: CBService?
    
    // Variables to communicate the state of a charecteristic to and from the arduino
    var charOne: CBCharacteristic?
    var charTwo: CBCharacteristic?
    
    // DECLARING BLUETOOTH VARIABLES: ENDS HERE
    
    @IBOutlet weak var colourChanger: UIView!
    
    
    @IBOutlet weak var sliderLed: UISlider!
    

    @IBAction func sliderResponser(_ sender: UISlider) {
        
        guard arduinoPeripheral != nil else {
            return
        }

        guard charOne != nil else {
            return
        }
        
        var sliderValue = Int(sender.value)
        
        let sliderData = Data(bytes: &sliderValue, count: MemoryLayout.size(ofValue: sliderValue))
        
        arduinoPeripheral?.writeValue(sliderData, for: charOne!, type: .withResponse)
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
        self.sliderLed.isContinuous = false
    }


}

extension ViewController: CBCentralManagerDelegate{
    
    // Scanning for a Peripherial with a Unique accessory UUID. This id the arduino UUID
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices:[CBUUID(string: ACCESSORY_UUID)], options: nil)
        }
    }
    
    // Success message in the console if there is a successful message to the accessory
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("Sucessful connection to Arduino Device")
        
        peripheral.delegate = self
        
        peripheral.discoverServices([CBUUID(string: SERVICE_ONE_UUID)])
        peripheral.discoverServices([CBUUID(string: SERVICE_TWO_UUID)])
        
    }
    
    // if the peripherial with the defined UUID(ACCESSORY_UUID) is discovered and connected then stop scanning for other bluetooth devices.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        arduinoPeripheral = peripheral
        
        if let connectedPeripheral = arduinoPeripheral {
            connectedPeripheral.delegate = self
            centralManager?.connect(connectedPeripheral, options: nil)
        }
        centralManager?.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
//        let alert = UIAlertController(title: "Bluetooh connection lost", message: "Possible failure scenarios. Bluetooh not turned on. Too far away from device", preferredStyle: .alert)
//
//        alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: { _ in
//            print("Arduino Disconnected.")
//        }))
//
//        self.present(alert, animated: true, completion: nil)
        
        print("Bluetooth connection lost")
    }
    
}

extension ViewController: CBPeripheralDelegate{
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        print("Services Discovered one")
        

        
        guard let sensorOne = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_ONE_UUID)
        }) else {
            return
        }
        
        serviceOne = sensorOne
        
        peripheral.discoverCharacteristics([CBUUID(string: SERVICE_ONE_CHARACTERISTIC_UUID)], for: serviceOne!)
        
        
        guard let sensorTwo = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_TWO_UUID)
        }) else {
            return
        }
        
        serviceTwo = sensorTwo
        
        peripheral.discoverCharacteristics([CBUUID(string: SERVICE_TWO_CHARACTERISTIC_UUID)], for: serviceTwo!)

    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("Services Discovered")
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Charecterstics Discovered")
        
        guard let charectOne = service.characteristics?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_ONE_CHARACTERISTIC_UUID)
        }) else {
            return
        }
        
        charOne = charectOne
        
        guard let charectTwo = service.characteristics?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_TWO_CHARACTERISTIC_UUID)
        }) else {
            return
        }
        
        charTwo = charectTwo
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data =  characteristic.value else{
            return
        }
        
//        guard let peripheral = arduinoPeripheral else {
//            return
//        }
//
//        guard let button = charTwo else {
//            return
//        }
        
        guard arduinoPeripheral != nil else {
            return
        }
        
        guard charTwo != nil else {
            return
        }
        
        
//        var recievedData =  peripheral.readValue(for: charTwo!)
        
        let recievedValue = data.int8Value()
        
        if recievedValue > 0 {
            colourChanger.backgroundColor = .green
        } else {
            colourChanger.backgroundColor = .red
        }
        
        
    }

}

extension Data {
    static func dataWithValue(value: Int8) -> Data {
        var variableValue = value
        return Data(buffer: UnsafeBufferPointer(start: &variableValue, count: 1))
    }
    
    func int8Value() -> Int8 {
        return Int8(bitPattern: self[0])
    }
}


