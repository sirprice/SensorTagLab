//
//  ViewController.swift
//  SensorTag
//
//  Created by Carl-Johan Dahlman on 2016-12-06.
//  Copyright © 2016 cjdev. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
   
    
    // Title labels
    var titleLabel : UILabel!
    var statusLabel : UILabel!
    var ambientTemperatureLabel : UILabel!
    var objectTemperatureLabel : UILabel!
    
    
    // values
    var ambientTemperature: Double = 0.0 {
        didSet {
            ambientTemperatureLabel.text = "Ambient Temperature: \(ambientTemperature)"
        }
    }
    var objectTemperature: Double = 0.0 {
        didSet {
            objectTemperatureLabel.text = "Object Temperature: \(objectTemperature)"
        }
    }
    
    // BLE
    var centralManager : CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!
    
    // Table View
    var sensorTagTableView : UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Initialize central manager on load
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Set up title label
        titleLabel = UILabel()
        titleLabel.text = "Sensor Tag"
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: self.view.frame.midX, y: self.titleLabel.bounds.midY+28)
        self.view.addSubview(titleLabel)
        
        // Set up status label
        statusLabel = UILabel()
        statusLabel.textAlignment = NSTextAlignment.center
        statusLabel.text = "Loading..."
        statusLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        statusLabel.sizeToFit()
        //statusLabel.center = CGPoint(x: self.view.frame.midX, y: (titleLabel.frame.maxY + statusLabel.bounds.height/2) )
        statusLabel.frame = CGRect(x: self.view.frame.origin.x, y: self.titleLabel.frame.maxY, width: self.view.frame.width, height: self.statusLabel.bounds.height)
        self.view.addSubview(statusLabel)
        
        // Set up ambient temperature label
        ambientTemperatureLabel = UILabel()
        ambientTemperatureLabel.textAlignment = NSTextAlignment.center
        ambientTemperatureLabel.text = "Temperature: n/a"
        ambientTemperatureLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        ambientTemperatureLabel.sizeToFit()
        ambientTemperatureLabel.frame = CGRect(x: self.view.frame.origin.x, y: self.statusLabel.frame.maxY, width: self.view.frame.width, height: self.ambientTemperatureLabel.bounds.height)
        self.view.addSubview(ambientTemperatureLabel)
        
        // Set up object temperature label
        objectTemperatureLabel = UILabel()
        objectTemperatureLabel.textAlignment = NSTextAlignment.center
        objectTemperatureLabel.text = "Temperature: n/a"
        objectTemperatureLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        objectTemperatureLabel.sizeToFit()
        objectTemperatureLabel.frame = CGRect(x: self.view.frame.origin.x, y: self.ambientTemperatureLabel.frame.maxY, width: self.view.frame.width, height: self.objectTemperatureLabel.bounds.height)
        self.view.addSubview(objectTemperatureLabel)


        
    
        
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*!
     *  @method centralManagerDidUpdateState:
     *
     *  @param central  The central manager whose state has changed.
     *
     *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
     *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
     *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
     *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
     *                  manager become invalid and must be retrieved or discovered again.
     *
     *  @see            state
     *
     */
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripherals(withServices: nil, options: nil)
            self.statusLabel.text = "Searching for BLE Devices"

        } else {
            // Can have different conditions for all states if needed - show generic alert for now
            self.statusLabel.text = "Error, Bluetooth switched off or not initialized"
        }
    }
    
    
    
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Advertiesed Data: \(advertisementData.description)")
        
        if SensorTag.sensorTagFound(advertisementData) == true {
            
            // Update Status Label
            self.statusLabel.text = "Sensor Tag Found"
            
            // Stop scanning, set as the peripheral to use and establish connection
            self.centralManager.stopScan()
            self.sensorTagPeripheral = peripheral
            self.sensorTagPeripheral.delegate = self
            self.centralManager.connect(peripheral, options: nil)


        }
        else {
            self.statusLabel.text = "Sensor Tag NOT Found"
            //showAlertWithText(header: "Warning", message: "SensorTag Not Found")
        }
    }
    // Discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.statusLabel.text = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }
    
    
    // If disconnected, start searching again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.text = "Disconnected"
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    // Check if the service discovered is valid i.e. one of the following:
    // IR Temperature Service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.statusLabel.text = "Looking at peripheral services"
        for service in peripheral.services! {
            let thisService = service as CBService
            if SensorTag.isValidService(thisService) {
                // Discover characteristics of all valid services
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
    }

    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        self.statusLabel.text = "Enabling sensors"
        
        let enableValue: [UInt8] = [1]
        
        let enablyBytes = Data(bytes: enableValue , count: enableValue.count)
        
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            if SensorTag.isValidDataCharacteristic(thisCharacteristic) {
                // Enable Sensor Notification
                print("DataCharacteristic was valid: \(thisCharacteristic.description)")
                self.sensorTagPeripheral.setNotifyValue(true, for: thisCharacteristic)
            }
            if SensorTag.isValidConfigCharacteristic(thisCharacteristic) {
                // Enable Sensor
                print("ConfigCharacteristic was valid: \(thisCharacteristic.description)")
                self.sensorTagPeripheral.writeValue(enablyBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
        
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        self.statusLabel.text = "Connected"
        //print("Data recieved! ")
        
        if characteristic.uuid == IRTemperatureDataUUID {
            self.ambientTemperature = SensorTag.getAmbientTemperature(characteristic.value!)
            self.objectTemperature = SensorTag.getObjectTemperature(characteristic.value!, ambientTemperature: self.ambientTemperature)
           
        }
    }
}

