//
//  InterfaceController.swift
//  Mogeste WatchKit Extension
//
//  Created by Mengyang Shi on 1/30/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    



    @IBOutlet var accelerometerLabel: WKInterfaceLabel!
    @IBOutlet var gyroscopeLabel: WKInterfaceLabel!
    
    var motion = CMMotionManager()
    
    var session : WCSession!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
       
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
    
    @IBAction func startRecord() {
        print("default motion update rate: \(motion.deviceMotionUpdateInterval)")
        motion.deviceMotionUpdateInterval = 0.02
        motion.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(data,error) in
            if let trueData = data {
                self.accelerometerLabel.setText("\(trueData.userAcceleration.x)")
                self.gyroscopeLabel.setText("\(trueData.rotationRate.x)")
                self.sendDataToIphone(accData: "\(trueData.userAcceleration.x),\(trueData.userAcceleration.y),\(trueData.userAcceleration.z)", gyroData: "\(trueData.rotationRate.x),\(trueData.rotationRate.y),\(trueData.rotationRate.z)")
                
            }
            
        })
    }

    @IBAction func stopRecord() {
        motion.stopDeviceMotionUpdates()
        print("stopped")
    }
    
    func sendDataToIphone(accData: String, gyroData: String) {
        let message = ["acc": accData, "gyro": gyroData]
        do {
            try session.updateApplicationContext(message)
        } catch {
            print("error")
        }
        //self.session.sendMessage(message, replyHandler: nil, errorHandler:{error in
        //    print(error.localizedDescription)
        //})
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let transfer = applicationContext["transfer"] as? String
        DispatchQueue.main.async() {
            if transfer == "start" {
                print("start")
                self.startRecord()
            } else if transfer == "stop" {
                print("stop")
                self.stopRecord()
            }
        }
    }
    

    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("session activated with state: \(activationState.rawValue)")
    }

}
