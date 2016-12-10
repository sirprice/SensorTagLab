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

class ViewController: UIViewController {
   
    var dataEntries: [BarChartDataEntry] = []
    var chartData = BarChartData()
    var periodicInterval = 100
    var connected = false
    var networkCtl = NetworkController()
    var sensorTagCtl = SensorTagController()
    
    // Title labels
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var ambientTemperatureLabel: UILabel!
    @IBOutlet weak var objectTemperatureLabel: UILabel!

    @IBOutlet weak var ipaddress: UITextField!
    @IBOutlet weak var sliderLabel: UILabel!
    @IBAction func start(_ sender: Any) {
        if sensorTagCtl.connected {
            sensorTagCtl.startSensors(periodicInterval: self.periodicInterval)
            dataEntries = [BarChartDataEntry]()
            
        }
    }

    
    @IBOutlet weak var chart: BarChartView!
    @IBOutlet weak var port: UITextField!
    @IBAction func sliderChanged(_ sender: UISlider) {
        //todo send new conf 
        periodicInterval = Int(sender.value)
        sliderLabel.text = "\(periodicInterval*10) ms"
    }
  
    @IBAction func save(_ sender: UIButton) {
        if  sensorTagCtl.connected {
            
            sensorTagCtl.terminateSensors()
            
            // save and send data to server
            networkCtl.sendMesuredData(dataEntries: self.dataEntries)
            
            dataEntries = [BarChartDataEntry]()
        }
    }
    
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
    

    override func viewDidLoad() {
        super.viewDidLoad()

      
        // Initialize sensor controller
        sensorTagCtl.initializeSensorController()
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.notificationNewData), name: SensorTagController.notifyNewData, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.notificationNewState(_:)), name: SensorTagController.notifyNewState, object: nil)

        
        }
    
    
    func notificationNewData() {
        
        ambientTemperatureLabel.text = String(sensorTagCtl.ambientTemperature)
        objectTemperatureLabel.text = String(sensorTagCtl.objectTemperature)
        
        
        var index = 1
        dataEntries = [BarChartDataEntry]()
        
        for value in sensorTagCtl.dataEntries {
            
            let newData = BarChartDataEntry(x: Double(index), y: Double(value))
            self.dataEntries.append(newData)
            index += 1
        }
        
        updateChart()
        
        
        
    }
    func notificationNewState(_ notification: NSNotification) {
        print("new state")
        if let state = notification.userInfo?["state"] as? String {
            // do something with your image
            statusLabel.text = state
            print("State from Controller: \(state)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateChart (){
        
        var displayData: [BarChartDataEntry] = []
        if dataEntries.count > 20 {
            displayData = [BarChartDataEntry](dataEntries.dropFirst(dataEntries.count - 20))
            
        } else {
            displayData = self.dataEntries
        }
        
        let chartDataSet = BarChartDataSet(values: displayData, label: "Temperature Count")
        
        chartData = BarChartData(dataSet: chartDataSet)
        chart.data = chartData
        
        chart.notifyDataSetChanged()
        chart.maxVisibleCount = 5
        chart.moveViewToX(Double(chartData.entryCount))
    }
}








