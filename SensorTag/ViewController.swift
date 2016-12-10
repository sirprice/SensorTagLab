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

class ViewController: UIViewController, UITextFieldDelegate {
    
    var dataEntries: [BarChartDataEntry] = []
    var chartData = BarChartData()
    var networkCtl = NetworkController()
    var sensorTagCtl = SensorTagController()
    var periodicInterval:Int {
        get{
            return (UserDefaults.standard.object(forKey: "periodicInterval") ?? 100) as! Int
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "periodicInterval")
        }
    }
    
    
    @IBOutlet weak var ipaddr: UITextField!
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(false)

    }
    
    @IBOutlet weak var chart: BarChartView!
    @IBOutlet weak var port: UITextField!
    @IBAction func sliderChanged(_ sender: UISlider) {
        //todo send new
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
    

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @IBAction func setIpPort(_ sender: UIButton) {
        //ipaddr.resignFirstResponder()
        if let ip:String = matches(for: "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}", in: ipaddr.text!).first{
            print(ip)
            if let port = Int(port.text!){
                UserDefaults.standard.set(ip, forKey: "ip")
                ipaddr.resignFirstResponder()
                UserDefaults.standard.set(port,forKey:"port")
            }
        }
    }
    
    @IBAction func ipChanged(_ sender: UITextField) {
        sender.text = sender.text?.replacingOccurrences(of: ",", with: ".")
    }

    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    

    
    

    override func viewDidLoad() {
        super.viewDidLoad()

      
        // Initialize sensor controller
        sensorTagCtl.initializeSensorController()
        
        
        

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.notificationNewData), name: SensorTagController.notifyNewData, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.notificationNewState(_:)), name: SensorTagController.notifyNewState, object: nil)

        
        self.ipaddr.delegate = self
        // Initialize central manager on load
        
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



    func notificationNewData() {
        
        ambientTemperatureLabel.text = String(sensorTagCtl.ambientTemperature)
        objectTemperatureLabel.text = String(sensorTagCtl.objectTemperature)
        
        
        var index = 1
        dataEntries = [BarChartDataEntry]()
        
        for value in sensorTagCtl.dataEntries {
            
            let data = BarChartDataEntry(x: Double(index), y: Double(value))
            dataEntries.append(data)
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








