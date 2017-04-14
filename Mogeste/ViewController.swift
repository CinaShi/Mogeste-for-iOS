//
//  ViewController.swift
//  Mogeste
//
//  Created by Mengyang Shi on 1/30/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreMotion

class ViewController: UIViewController, WCSessionDelegate {
    
    @IBOutlet weak var accDataDisplay: UILabel!
    @IBOutlet weak var gyroDataDisplay: UILabel!
    

    struct Acceleration {
        var x:Float! = 0
        var y:Float! = 0
        var z:Float! = 0
    }
    
    struct Gyroscope {
        var x:Float! = 0
        var y:Float! = 0
        var z:Float! = 0
    }
    
    var accDataList = [Acceleration]()
    var gyroDataList = [Gyroscope]()
    
    var session: WCSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if WCSession.isSupported(){
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        print("hey I'm ios")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    @IBAction func startTransfer(_ sender: Any) {
        let message = ["transfer": "start"]
        do {
            try session.updateApplicationContext(message)
        } catch {
            print("error")
        }
//        self.session.sendMessage(message, replyHandler: nil, errorHandler:{error in
//            print(error.localizedDescription)
//        })
    }
    
    @IBAction func stopTransfer(_ sender: Any) {
        let message = ["transfer": "stop"]
        do {
            try session.updateApplicationContext(message)
            
        } catch {
            print("error")
        }

//        self.session.sendMessage(message, replyHandler: nil, errorHandler:{error in
//            print(error.localizedDescription)
//        })
    }
    
    
    @IBAction func printList(_ sender: Any) {
        print("stopped")
        print("acc data ----->")
        for accData in self.accDataList {
            print("x=\(accData.x), y=\(accData.y), z=\(accData.z)")
        }
        print("gyro data ----->")
        for gyroData in self.gyroDataList {
            print("x=\(gyroData.x), y=\(gyroData.y), z=\(gyroData.z)")
        }
    }
    
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let accData = applicationContext["acc"] as? String
        let gyroData = applicationContext["gyro"] as? String
        DispatchQueue.main.async() {
            guard let accArr = accData?.components(separatedBy: ",") else {
                return
            }
            guard let gyroArr = gyroData?.components(separatedBy: ",") else {
                return
            }
            
            self.accDataDisplay.text = "x=\(accArr[0]), y=\(accArr[1]), z=\(accArr[2])"
            
           
            self.gyroDataDisplay.text = "x=\(gyroArr[0]), y=\(gyroArr[1]), z=\(gyroArr[2])"
            
            self.accDataList.append(Acceleration(x:Float(accArr[0]), y:Float(accArr[1]), z:Float(accArr[2])))
            self.gyroDataList.append(Gyroscope(x:Float(gyroArr[0]), y:Float(gyroArr[1]), z:Float(gyroArr[2])))
        }
    }
    
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("session activated with state: \(activationState.rawValue)")
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session did deactivate")
        session.activate()
    }
    
    


}

