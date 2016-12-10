//
//  SensorTagConroller.swift
//  SensorTag
//
//  Created by Carl-Johan Dahlman on 2016-12-10.
//  Copyright © 2016 cjdev. All rights reserved.
//

import Foundation
import CoreBluetooth

class SensorTagController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let notifyNewData = Notification.Name("notifyNewData")
    static let notifyNewState = Notification.Name("notifyState")

    
    func initializeSensorController() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    var datanr = 0
    var dataEntries: [Double] = []
    var connected = false
    var networkCtl = NetworkController()
    var tagService: CBService? = nil
    
    // BLE
    var centralManager : CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!
    
    var ambientTemperature: Double = 0.0 {
        didSet {
            //ambientTemperatureLabel.text = "Ambient Temperature: \(ambientTemperature)"
        }
    }
    var objectTemperature: Double = 0.0 {
        didSet {
            //objectTemperatureLabel.text = "Object Temperature: \(objectTemperature)"
        }
    }

    
    
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripherals(withServices: nil, options: nil)
            //self.statusLabel.text = "Searching for BLE Devices"
            
        } else {
            // Can have different conditions for all states if needed - show generic alert for now
            //self.statusLabel.text = "Error, Bluetooth switched off or not initialized"
        }
    }
    
    
    
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Advertiesed Data: \(advertisementData.description)")
        
        if SensorTag.sensorTagFound(advertisementData) == true {
            
            
            let state:[String: String] = ["state": "SensorTag Found"]
            NotificationCenter.default.post(name: SensorTagController.notifyNewState, object: nil, userInfo: state)
            
            // Stop scanning, set as the peripheral to use and establish connection
            self.centralManager.stopScan()
            self.sensorTagPeripheral = peripheral
            self.sensorTagPeripheral.delegate = self
            self.centralManager.connect(peripheral, options: nil)
            
            
        }
        else {
            //self.statusLabel.text = "Sensor Tag NOT Found"
            //showAlertWithText(header: "Warning", message: "SensorTag Not Found")
        }
    }
    // Discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let state:[String: String] = ["state": "Discovering peripheral services"]
        NotificationCenter.default.post(name: SensorTagController.notifyNewState, object: nil, userInfo: state)
        peripheral.discoverServices(nil)
        connected = false
    }
    
    
    // If disconnected, start searching again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        let state:[String: String] = ["state": "Disconnected"]
        NotificationCenter.default.post(name: SensorTagController.notifyNewState, object: nil, userInfo: state)
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // Check if the service discovered is valid i.e. one of the following:
    // IR Temperature Service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let state:[String: String] = ["state": "Looking at peripheral services"]
        NotificationCenter.default.post(name: SensorTagController.notifyNewState, object: nil, userInfo: state)
        for service in peripheral.services! {
            let thisService = service as CBService
            if SensorTag.isValidService(thisService) {
                // Discover characteristics of all valid services
                peripheral.discoverCharacteristics(nil, for: thisService)
                
            }
        }
    }
    
    
    // sätter igång utvalda sensorer i SensorTagen
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let state:[String: String] = ["state": "Connected"]
        NotificationCenter.default.post(name: SensorTagController.notifyNewState, object: nil, userInfo: state )

        print("Found service")
        self.tagService = service
        self.connected = true
        
    }
    
    // sensortaggen är nu redo för att göra stordåd. och tar nu emot data :)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == IRTemperatureDataUUID {
            //print("Data recieved! ")
            datanr += 1
            self.ambientTemperature = SensorTag.getAmbientTemperature(characteristic.value!)
            self.objectTemperature = SensorTag.getObjectTemperature(characteristic.value!)
            
            //let newData = BarChartDataEntry(x: Double(datanr), y: Double(SensorTag.getObjectTemperature(characteristic.value!)))
            self.dataEntries.append(objectTemperature)
            UserDefaults.standard.set(dataEntries,forKey:"dataEntries")
            //UserDefaults.standard.synchronize()
            //print(UserDefaults.standard.array(forKey: "dataEntries") as! [Double])
            NotificationCenter.default.post(name: SensorTagController.notifyNewData, object: nil)

            //updateChart()
        }
    }
    
    
    func terminateSensors(){
        
        //"Terminating sensors"
        
        print("before terminating, size: \(dataEntries.count)")
        dataEntries = [Double]()
        
        let enableValue: [UInt8] = [0]
        
        let enablyBytes = Data(bytes: enableValue , count: enableValue.count)
        if let arr = self.tagService?.characteristics {
            for charateristic in arr {
            
                let thisCharacteristic = charateristic as CBCharacteristic
            
                if SensorTag.isValidDataCharacteristic(thisCharacteristic) {
                // Enable Sensor Notification
                    print("DataCharacteristic was valid: \(thisCharacteristic.description)")
                //self.sensorTagPeripheral.setNotifyValue(false, for: thisCharacteristic)
                }
                if SensorTag.isValidConfigCharacteristic(thisCharacteristic) {
                // Enable Sensor
                    print("ConfigCharacteristic was valid: \(thisCharacteristic.description)")
                    self.sensorTagPeripheral.writeValue(enablyBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
                
                }
            }
        }
        
    }
    
    
    func startSensors(periodicInterval: Int){
        // starting sensors
        dataEntries = [Double]()
        if let tmp = self.tagService?.characteristics{
        for charateristic in tmp {
            let thisCharacteristic = charateristic as CBCharacteristic
            if SensorTag.isValidDataCharacteristic(thisCharacteristic) {
                // Enable Sensor Notification
                print("DataCharacteristic was valid: \(thisCharacteristic.description)")
                self.sensorTagPeripheral.setNotifyValue(true, for: thisCharacteristic)
            }
            
            if SensorTag.isValidConfigCharacteristic(thisCharacteristic) {
                // Enable Sensor
                let enableValue: [UInt8] = [1]
                let enablyBytes = Data(bytes: enableValue , count: enableValue.count)
                
                print("ConfigCharacteristic was valid: \(thisCharacteristic.description)")
                self.sensorTagPeripheral.writeValue(enablyBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
                
            }
            if  SensorTag.isValidPeriodCharacteristic(thisCharacteristic){
                // Setting period
                let periodValue: [UInt8] = [UInt8(periodicInterval)]
                let periodBytes = Data(bytes: periodValue , count: periodValue.count)
                print("PeriodCharacteristic was valid: \(thisCharacteristic.description)")
                self.sensorTagPeripheral.writeValue(periodBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
            }
        }
    }
}
