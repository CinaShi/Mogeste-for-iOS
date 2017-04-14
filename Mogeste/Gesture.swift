//
//  Gesture.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/15/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit
import MetaWear

class Gesture: NSObject, NSCoding {
    let gestureName: String!
    var samples: [Sample]!
    let gid: Int!
    
    init(gestureName: String, samples: [Sample], gid: Int){
        self.gestureName = gestureName
        self.samples = samples
        self.gid = gid
    }
    
    required init(coder decoder: NSCoder){
        self.gestureName = decoder.decodeObject(forKey: "gestureName") as! String
        self.samples = decoder.decodeObject(forKey: "samples") as! [Sample]
        self.gid = decoder.decodeInteger(forKey: "gid") 
    }
    
    func encode(with aCoder: NSCoder) {
        if let gestureName = gestureName {
            aCoder.encode(gestureName, forKey:"gestureName")
        }
        if let samples = samples {
            aCoder.encode(samples, forKey:"samples")
        }
        if let gid = gid {
            aCoder.encode(gid, forKey:"gid")
        }
    }
    
    func append(sample: Sample) {
        self.samples.append(sample)
    }
    
    func remove(index: Int) {
        self.samples.remove(at: index)
    }
    
    func samplesCount() -> Int {
        return samples.count
    }
}
