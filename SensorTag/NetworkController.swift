//
//  NetworkController.swift
//  SensorTag
//
//  Created by Carl-Johan Dahlman on 2016-12-10.
//  Copyright © 2016 cjdev. All rights reserved.
//

import Foundation
import Charts

class NetworkController {
    
    
    func sendMesuredData(dataEntries: [BarChartDataEntry]){
        print("Messured data: \(dataEntries.description)")
        print("Messured size: \(dataEntries.count)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let tvp = TCPManager(addr: "130.229.155.100", port: 6667)
            // tvp.reconnect()
            tvp.sendMesuredData(dataEntries: dataEntries)
            tvp.close()
            print("connect")
        }

        
    }
    
    
}
