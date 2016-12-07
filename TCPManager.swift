//
//  TCPManager.swift
//  SensorTag
//
//  Created by lucas persson on 2016-12-07.
//  Copyright © 2016 cjdev. All rights reserved.
//

import Foundation

class TCPManager {
    private var outputStream:OutputStream
    private var inputStream:InputStream
    init(addr:String,port:Int){
        var inp :InputStream?
        var out :OutputStream?
        Stream.getStreamsToHost(withName: addr, port: port, inputStream: &inp, outputStream: &out)
        
        inputStream = inp!
        outputStream = out!
        inputStream.open()
        outputStream.open()
        
        //dont need maybe remove
        var readByte :UInt8 = 0
        while inputStream.hasBytesAvailable {
            inputStream.read(&readByte, maxLength: 1)
            print(read)
        }
    }
    
    func close(){
        outputStream.close()
        inputStream.close()
    }
    
    func sendString(_ back:String) -> Int{
        return outputStream.write(back, maxLength:back.cString(using: .utf8)!.count)
    }
    
    
}
