//
//  SensorTag.swift
//  SensorTag
//
//  Created by Carl-Johan Dahlman on 2016-12-06.
//  Copyright © 2016 cjdev. All rights reserved.
//

import Foundation
import CoreBluetooth

let deviceName = "CC2650 SensorTag"

// IR temp service UUIDs
let IRTemperatureServiceUUID = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")

// Characteristics
let IRTemperatureDataUUID   = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
let IRTemperatureConfigUUID = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")

class SensorTag {
    
    
    // Check name of device from advertisement data
    class func sensorTagFound (_ advertisementData: [String: Any]!) -> Bool {
  
        
        for i in advertisementData.enumerated() {
            if let nameOfDeviceFound:String = i.element.value as? String {
                
                if  nameOfDeviceFound == deviceName {
                    return true
                }
            }
        }
        
        return false
    }
    
    
}

