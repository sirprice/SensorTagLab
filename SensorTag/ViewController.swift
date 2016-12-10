//
//  ViewController.swift
//  SensorTag
//
//  Created by Carl-Johan Dahlman on 2016-12-06.
//  Copyright © 2016 cjdev. All rights reserved.
//

import UIKit
import CoreBluetooth
import Charts

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
   
    var datanr = 0
    var dataEntries: [BarChartDataEntry] = []
    var chartData = BarChartData()
    var lineDataSet = LineChartDataSet()
    // Title labels
    var titleLabel : UILabel!
    var statusLabel : UILabel!
    var ambientTemperatureLabel : UILabel!
    var objectTemperatureLabel : UILabel!
    
    @IBOutlet weak var chart: BarChartView!
  
    
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
        //updateChartWithData()
        //lineDataSet = LineChartDataSet(values: dataEntries, label: "dynamic")
        
        //chartData.dataSets.append(lineDataSet)
        
        //chart.data = chartData
        
        
        //TODO make sure that tcp manager dont hang the app
        DispatchQueue.global(qos: .userInitiated).async {
        let tvp = TCPManager(addr: "130.229.133.95", port: 6667)
       // tvp.reconnect()
            tvp.sendString("iphone hi")//todo example only
            tvp.close()
            print("connect")
        }
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

    
    // sätter igång utvalda sensorer i SensorTagen
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
//        self.statusLabel.text = "Enabling sensors"
//        
//        let enableValue: [UInt8] = [1]
//        
//        let enablyBytes = Data(bytes: enableValue , count: enableValue.count)
//        
//        for charateristic in service.characteristics! {
//            let thisCharacteristic = charateristic as CBCharacteristic
//            if SensorTag.isValidDataCharacteristic(thisCharacteristic) {
//                // Enable Sensor Notification
//                print("DataCharacteristic was valid: \(thisCharacteristic.description)")
//                self.sensorTagPeripheral.setNotifyValue(true, for: thisCharacteristic)
//            }
//            if SensorTag.isValidConfigCharacteristic(thisCharacteristic) {
//                // Enable Sensor
//                print("ConfigCharacteristic was valid: \(thisCharacteristic.description)")
//                self.sensorTagPeripheral.writeValue(enablyBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
//            }
//        }
    }

    // sensortaggen är nu redo för att göra stordåd. och tar nu emot data :) 
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        self.statusLabel.text = "Connected"

        if characteristic.uuid == IRTemperatureDataUUID {
            //print("Data recieved! ")
            datanr += 1
            self.ambientTemperature = SensorTag.getAmbientTemperature(characteristic.value!)
            self.objectTemperature = SensorTag.getObjectTemperature(characteristic.value!)
            
            let newData = BarChartDataEntry(x: Double(datanr), y: Double(SensorTag.getObjectTemperature(characteristic.value!)))
            dataEntries.append(newData)
            
            
            var displayData: [BarChartDataEntry] = []
            if dataEntries.count > 20 {
                displayData = [BarChartDataEntry](dataEntries.dropFirst(dataEntries.count - 20))
                
            } else {
                displayData = dataEntries
            }
            
            let chartDataSet = BarChartDataSet(values: displayData, label: "Temperature Count")
        
            chartData = BarChartData(dataSet: chartDataSet)
            chart.data = chartData
            
            chart.notifyDataSetChanged()
            chart.maxVisibleCount = 5
            chart.moveViewToX(Double(chartData.entryCount))
            
        }
    }
    
    func terminateSensors(){
        
        self.statusLabel.text = "Terminating sensors"
        
        let enableValue: [UInt8] = [0]
        
        let enablyBytes = Data(bytes: enableValue , count: enableValue.count)
        
        for service in self.sensorTagPeripheral.services! {
            
            for charateristic in service.characteristics! {
                
                let thisCharacteristic = charateristic as CBCharacteristic
                
                if SensorTag.isValidDataCharacteristic(thisCharacteristic) {
                    // Enable Sensor Notification
                    print("DataCharacteristic was valid: \(thisCharacteristic.description)")
                    self.sensorTagPeripheral.setNotifyValue(false, for: thisCharacteristic)
                }
                if SensorTag.isValidConfigCharacteristic(thisCharacteristic) {
                    // Enable Sensor
                    print("ConfigCharacteristic was valid: \(thisCharacteristic.description)")
                    self.sensorTagPeripheral.writeValue(enablyBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
              
                }
            }
        }
    }
    
    func startSensors(){
        self.statusLabel.text = "Enabling sensors"
        
       
        
        for service in self.sensorTagPeripheral.services! {
            for charateristic in service.characteristics! {
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
                    let periodValue: [UInt8] = [50]
                    let periodBytes = Data(bytes: periodValue , count: periodValue.count)
                    print("PeriodCharacteristic was valid: \(thisCharacteristic.description)")
                    self.sensorTagPeripheral.writeValue(periodBytes, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        }
    }
}








