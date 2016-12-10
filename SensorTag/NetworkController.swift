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
           /* let tvp = TCPManager(addr: "130.229.155.100", port: 6667)
            // tvp.reconnect()
            tvp.sendMesuredData(dataEntries: dataEntries)
            tvp.close()
            print("connect")
            */
            let addr =  UserDefaults.standard.string(forKey: "ip") ?? "130.229.155.100"
            let port =  UserDefaults.standard.object(forKey: "port") as? Int ?? 6667
            print("sending to \(addr) port\(port)")
            var inp :InputStream?
            var out :OutputStream?
            Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inp, outputStream: &out)
            //print()
            let outputStream = out!
            outputStream.open()
            outputStream.write(dataEntries.description, maxLength:dataEntries.description.cString(using: .utf8)!.count)
            outputStream.close()
        }

        
    }
    
    
}
