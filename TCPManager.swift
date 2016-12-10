//
//  TCPManager.swift
//  SensorTag
//
//  Created by lucas persson on 2016-12-07.
//  Copyright © 2016 cjdev. All rights reserved.
//

import Foundation
import Charts

class TCPManager {
    private var outputStream:OutputStream?
    private var inputStream:InputStream?
    private var addr:String
    private var port:Int
    init(addr:String,port:Int){
        self.addr = addr
        self.port = port
        connect()
    }
    
    private func connect(){
        var inp :InputStream?
        var out :OutputStream?
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inp, outputStream: &out)
        //print()
        inputStream = inp!
        outputStream = out!
        inputStream!.open()
        outputStream!.open()
        
        //dont need maybe remove
        var readByte :UInt8 = 0
        while inputStream!.hasBytesAvailable {
            inputStream!.read(&readByte, maxLength: 1)
            print(read)
        }
        
    }
    
    func reconnect(){
        close()
        connect()
    }
    
    func close(){
        outputStream?.close()
        inputStream?.close()
    }
    
    func sendString(_ back:String) -> Int{
        return (outputStream?.write(back, maxLength:back.cString(using: .utf8)!.count)) ?? -2
    }
    
    func sendMesuredData(dataEntries: [BarChartDataEntry]){
        print("Messured data: \(dataEntries.description)")
        print("Messured size: \(dataEntries.count)")
        
    }
    
    
}
