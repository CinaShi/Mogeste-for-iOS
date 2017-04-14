//
//  Sample.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/13/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//
import UIKit
import MetaWear

class Sample: NSObject, NSCoding {
    var length: Int = 0
    let accData: [SensorData]!
    let gyroData: [SensorData]!
    let gesture: String!
    
    init(length: Int, accData: [SensorData], gyroData: [SensorData], gesture: String){
        self.length = length
        self.accData = accData
        self.gyroData = gyroData
        self.gesture = gesture
    }
    
    required init(coder decoder: NSCoder){
        self.length = decoder.decodeInteger(forKey: "length")
        self.accData = decoder.decodeObject(forKey: "accData") as! [SensorData]
        self.gyroData = decoder.decodeObject(forKey: "gyroData") as! [SensorData]
        self.gesture = decoder.decodeObject(forKey: "gesture") as! String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(length, forKey:"length")
        if let accData = accData {
            aCoder.encode(accData, forKey:"accData")
        }
        if let gyroData = gyroData {
            aCoder.encode(gyroData, forKey:"gyroData")
        }
        if let gesture = gesture {
            aCoder.encode(gesture, forKey:"gesture")
        }
        
    }
}
