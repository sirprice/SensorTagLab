//
//  SensorTag.swift
//  SensorTag
//
//  Created by Carl-Johan Dahlman on 2016-12-06.
//  Copyright © 2016 cjdev. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

let deviceName = "CC2650 SensorTag"

// IR temp service UUIDs
let IRTemperatureServiceUUID = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")

// Characteristics
let IRTemperatureDataUUID   = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
let IRTemperatureConfigUUID = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")

class SensorTag {
    
    static let SCALE_LSB = 0.03125;

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
    
    class func getAmbientTemperature(_ val: Data) -> Double {
        //let a =
        //print(val)
               let amb = Double( (Int(val[2]) * 8 ) + Int( val[3])) * SCALE_LSB
        //print(amb)
        return amb
    }
    
    class func getObjectTemperature(_ val: Data) -> Double {
        return Double( (Int(val[0]) * 8 ) + Int( val[1])) * SCALE_LSB
    }

    
    // Get ambient temperature value
    class func getAmbientTemperatureBad(_ value : Data) -> Double {
        let count = value.count
        var array = [Int8](repeating: 0, count: count)
        (value as NSData).getBytes(&array, length:count * MemoryLayout<Int8>.size)

        let ambientTemperature = Double(array[1])/128
        return ambientTemperature
    }
    
    // Get object temperature value
    class func getObjectTemperatureBad(_ value : Data, ambientTemperature : Double) -> Double {
        
        let count = value.count
        var array = [Int8](repeating: 0, count: count)
        (value as NSData).getBytes(&array, length:count * MemoryLayout<Int8>.size)
        
        let Vobj2 = Double(array[0]) * 0.00000015625
        
        let Tdie2 = ambientTemperature + 273.15
        let Tref  = 298.15
        
        let S0 = 6.4e-14
        let a1 = 1.75E-3
        let a2 = -1.678E-5
        let b0 = -2.94E-5
        let b1 = -5.7E-7
        let b2 = 4.63E-9
        let c2 = 13.4
        
        let S = S0*(1+a1*(Tdie2 - Tref)+a2*pow((Tdie2 - Tref),2))
        let Vos = b0 + b1*(Tdie2 - Tref) + b2*pow((Tdie2 - Tref),2)
        let fObj = (Vobj2 - Vos) + c2*pow((Vobj2 - Vos),2)
        let tObj = pow(pow(Tdie2,4) + (fObj/S),0.25)
        
        let objectTemperature = (tObj - 273.15)
        
        return objectTemperature
    }

    
    class func isValidService (_ service : CBService) -> Bool {
        if service.uuid == IRTemperatureServiceUUID {
            return true
        }
        return false
    }
    
    
    class func isValidDataCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        if characteristic.uuid == IRTemperatureDataUUID {
            return true
        }
        return false
    }
    
    class func isValidConfigCharacteristic(_ characteristic : CBCharacteristic) -> Bool {
        if characteristic.uuid == IRTemperatureConfigUUID {
            return true
        }
        return false

    }
}

