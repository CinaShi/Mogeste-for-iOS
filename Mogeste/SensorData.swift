//
//  SensorData.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/15/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit
import MetaWear

class SensorData: NSObject, NSCoding {
    let x:Double!
    let y:Double!
    let z:Double!
    let timestamp:Date!
    
    
    init(x: Double, y: Double, z: Double, timestamp: Date){
        self.x = x
        self.y = y
        self.z = z
        self.timestamp = timestamp
    }
    
    required init(coder decoder: NSCoder){
        self.x = decoder.decodeDouble(forKey: "x")
        self.y = decoder.decodeDouble(forKey: "y")
        self.z = decoder.decodeDouble(forKey: "z")
        self.timestamp = decoder.decodeObject(forKey: "timestamp") as! Date
        
        
    }
    
    func encode(with aCoder: NSCoder) {
        if let x = x {
            aCoder.encode(x, forKey:"x")
        }
        if let y = y {
            aCoder.encode(y, forKey:"y")
        }
        if let z = z {
            aCoder.encode(z, forKey:"z")
        }
        if let timestamp = timestamp {
            aCoder.encode(timestamp, forKey:"timestamp")
        }
        
    }
}
