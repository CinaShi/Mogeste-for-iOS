//
//  DeviceDetailViewController.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/8/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit
import StaticDataTableViewController
import MetaWear
import MessageUI
import Bolts
import MBProgressHUD
import iOSDFULibrary
import SigmaSwiftStatistics

extension String {
    var drop0xPrefix:          String { return hasPrefix("0x") ? String(characters.dropFirst(2)) : self }
}


class DeviceDetailViewController: StaticDataTableViewController, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate, DFUPeripheralSelectorDelegate {
    var device: MBLMetaWear!
    var gestureName: String!
    var newSample: Sample?
    var accData = [SensorData]()
    var gyroData = [SensorData]()
    var VCsourceIdentifier: String!
    
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var connectionSwitch: UISwitch!
    @IBOutlet weak var connectionStateLabel: UILabel!
    
    @IBOutlet weak var startRecordingButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    
    
    @IBOutlet weak var accelerometerCell: UITableViewCell!
    @IBOutlet weak var accXLabel: UILabel!
    @IBOutlet weak var accYLabel: UILabel!
    @IBOutlet weak var accZLabel: UILabel!
    @IBOutlet weak var accTimestampLabel: UILabel!
    
    @IBOutlet weak var gyroscopeCell: UITableViewCell!
    @IBOutlet weak var gyroXLabel: UILabel!
    @IBOutlet weak var gyroYLabel: UILabel!
    @IBOutlet weak var gyroZLabel: UILabel!
    @IBOutlet weak var gyroTimestampLabel: UILabel!
    
    var gestureToTrain: [Gesture]?
    var gestureNamesToClassify: [String]?
    
    private var nextNextGaussian: Double? = {
        srand48(Int(arc4random())) //initialize drand48 buffer at most once
        return nil
    }()
    
    var streamingEvents: Set<NSObject> = []
    var hud: MBProgressHUD!
    
    var isObserving = false {
        didSet {
            if self.isObserving {
                if !oldValue {
                    self.device.addObserver(self, forKeyPath: "state", options: .new, context: nil)
                }
            } else {
                if oldValue {
                    self.device.removeObserver(self, forKeyPath: "state")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        print(gestureName)
        // Use this array to keep track of all streaming events, so turn them off
        // in case the user isn't so responsible
        streamingEvents = []
        // Hide every section in the beginning
        hideSectionsWithHiddenRows = true
        //cells(self.allCells, setHidden: true)
        //reloadData(animated: false)
        // Write in the 2 fields we know at time zero
        connectionStateLabel.text = nameForState()
        // Listen for state changes
        isObserving = true
        // Start off the connection flow
        connectDevice(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isObserving = false
        for obj in streamingEvents {
            if let event = obj as? MBLEvent<AnyObject> {
                event.stopNotificationsAsync()
            }
        }
        streamingEvents.removeAll()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        OperationQueue.main.addOperation {
            self.connectionStateLabel.text = self.nameForState()
            if self.device.state == .disconnected {
                self.deviceDisconnected()
            }
        }
    }
    
    func nameForState() -> String {
        switch device.state {
        case .connected:
            return device.programedByOtherApp ? "Connected (LIMITED)" : "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        case .discovery:
            return "Discovery"
        }
    }
    
    func logCleanup(_ handler: @escaping MBLErrorHandler) {
        // In order for the device to actaully erase the flash memory we can't be in a connection
        // so temporally disconnect to allow flash to erase.
        isObserving = false
        device.disconnectAsync().continueOnDispatch { t in
            self.isObserving = true
            guard t.error == nil else {
                return t
            }
            return self.device.connect(withTimeoutAsync: 15)
            }.continueOnDispatch { t in
                handler(t.error)
                return nil
        }
    }
    
    func showAlertTitle(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func deviceDisconnected() {
        connectionSwitch.setOn(false, animated: true)
    }
    
    func deviceConnected() {
        connectionSwitch.setOn(true, animated: true)
        // Perform all device specific setup
        if let mac = device.settings?.macAddress {
            mac.readAsync().success { result in
                print("ID: \(self.device.identifier.uuidString) MAC: \(result.value)")
            }
        } else {
            print("ID: \(device.identifier.uuidString)")
        }
        
        
    }
    
    func connectDevice(_ on: Bool) {
        
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        if on {
            hud.label.text = "Connecting..."
            device.connect(withTimeoutAsync: 15).continueOnDispatch { t in
                if (t.error?._domain == kMBLErrorDomain) && (t.error?._code == kMBLErrorOutdatedFirmware) {
                    hud.hide(animated: true)
//                    self.firmwareUpdateLabel.text! = "Force Update"
//                    self.updateFirmware(self.setNameButton)
                    return nil
                }
                hud.mode = .text
                if t.error != nil {
                    self.showAlertTitle("Error", message: t.error!.localizedDescription)
                    hud.hide(animated: false)
                } else {
                    self.deviceConnected()
                    
                    hud.label.text! = "Connected!"
                    hud.hide(animated: true, afterDelay: 0.5)
                }
                return nil
            }
        } else {
            hud.label.text = "Disconnecting..."
            device.disconnectAsync().continueOnDispatch { t in
                self.deviceDisconnected()
                hud.mode = .text
                if t.error != nil {
                    self.showAlertTitle("Error", message: t.error!.localizedDescription)
                    hud.hide(animated: false)
                }
                else {
                    hud.label.text = "Disconnected!"
                    hud.hide(animated: true, afterDelay: 0.5)
                }
                return nil
            }
        }
    }
    
    @IBAction func connectionSwitchPressed(_ sender: Any) {
        connectDevice(connectionSwitch.isOn)
    }
    
    
    @IBAction func startRecording(_ sender: Any) {
        self.startRecordingButton.isEnabled = false
        self.stopRecordingButton.isEnabled = true
        self.saveButton.isEnabled = false
        
        accData.removeAll()
        gyroData.removeAll()
        
        accelerometerStartStream()
        gyroscopeStartStream()
    }
    
    
    @IBAction func stopRecording(_ sender: Any) {
        self.startRecordingButton.isEnabled = true
        self.startRecordingButton.setTitle("restart recording", for: UIControlState.normal)
        self.stopRecordingButton.isEnabled = false
        self.saveButton.isEnabled = true
        
        accelerometerStopStream()
        gyroscopeStopStream()
        
        while accData.count < gyroData.count {
            gyroData.remove(at: 0)
        }
        while accData.count > gyroData.count {
            accData.remove(at: 0)
        }
        
        
        
//        print(accelerometerData.count)
//        print(gyroscopeData.count)
//        print("first acc data's timestamp ----> \(accelerometerData.first!.timestamp)")
//        print("first gyro data's timestamp ----> \(gyroscopeData.first!.timestamp)")
    }
    
    @IBAction func saveAndExit(_ sender: Any) {
        createSampleObject()
    }
    
    func createSampleObject() {
        let startTime = accData.first?.timestamp
        let endTime = accData.last?.timestamp
        let duration = endTime!.timeIntervalSince(startTime!)
        let durationInMS = Int(duration * 1000)
        newSample = Sample(length:durationInMS, accData:accData, gyroData:gyroData, gesture:"default")
        
        if gestureToTrain != nil {
            
            do {
                let network = FFNN.fromFile(filename: "current network")
                
                //for testing
                if let decoded = UserDefaults.standard.object(forKey: "gestures") as? Data {
                    let gestures = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Gesture]
                    for gesture in gestures {
                        if gesture.gestureName == "test" {
                            var sampleNumber = 1
                            for testSample in gesture.samples {
                                let output:[Float] = try network!.update(inputs: calculateTrainingFeatures(sample: testSample))
                                print(output)
                                let predictedIndex = maxIndex(array: output)
                                if predictedIndex >= 0 {
                                    print("test sample \(sampleNumber) predicted ---> \(String(describing: (gestureNamesToClassify?[predictedIndex])!))")
                                    sampleNumber += 1
                                } else {
                                    print("some errors happen")
                                    break
                                }
                            }
                            break
                        }
                    }
                }
                
                
                //real situation
                let output:[Float] = try network!.update(inputs: calculateTrainingFeatures(sample: newSample!))
                print(output)
                let predictedIndex = maxIndex(array: output)
                if predictedIndex >= 0 {
                    print("new sample has been classified into: \(String(describing: (gestureNamesToClassify?[predictedIndex])!))")
                    newSample = Sample(length:durationInMS, accData:accData, gyroData:gyroData, gesture:(gestureNamesToClassify?[predictedIndex])!)
                    
                    let alertController = UIAlertController(title: "Result", message: "This sample has been classified into gesture: \((gestureNamesToClassify?[predictedIndex])!)", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Retrain", style: .default, handler: retrainGestures))
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: classificationSuccess))
                    self.present(alertController, animated: true, completion: nil)
                    
                } else {
                    print("some errors happen")
                }
                
                
            } catch {
                print(error)
            }
            
        } else {
            newSample = Sample(length:durationInMS, accData:accData, gyroData:gyroData, gesture:gestureName)
            if VCsourceIdentifier == "gestureList" {
                self.performSegue(withIdentifier: "unwindToGestureList", sender: self)
            } else if VCsourceIdentifier == "sampleList" {
                self.performSegue(withIdentifier: "unwindToSampleList", sender: self)
            }
        }
    }
    
    func retrainGestures(alert: UIAlertAction) {
        print("retrain here")
    }
    
    func classificationSuccess(alert: UIAlertAction) {
        self.performSegue(withIdentifier: "unwindToGestureList", sender: self)
    }
    
    
    func accelerometerStartStream() {
//        var array = [MBLAccelerometerData]() /* capacity: 1000 */
//        accelerometerData = array
        streamingEvents.insert(device.accelerometer!.dataReadyEvent)
        device.accelerometer!.sampleFrequency = 50
        device.accelerometer!.dataReadyEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                // TODO: Come up with a better graph interface, we need to scale value
                // to show up right
                self.accXLabel.text = "X = \(obj.x)"
                self.accYLabel.text = "Y = \(obj.y)"
                self.accZLabel.text = "Z = \(obj.z)"
                self.accTimestampLabel.text = "\(obj.timestamp)"
//                array.append(obj)
                self.accData.append(SensorData(x: obj.x, y: obj.y, z: obj.z, timestamp: obj.timestamp))
            }
        }
    }
    
    func accelerometerStopStream() {
        
        streamingEvents.remove(device.accelerometer!.dataReadyEvent)
        device.accelerometer!.dataReadyEvent.stopNotificationsAsync()
    }
    
    func gyroscopeStartStream() {
        
//        var array = [MBLGyroData]() /* capacity: 1000 */
//        gyroscopeData = array
        streamingEvents.insert(device.gyro!.dataReadyEvent)
        device.gyro!.sampleFrequency = 50
        device.gyro!.dataReadyEvent.startNotificationsAsync { (obj, error) in
            if let obj = obj {
                // TODO: Come up with a better graph interface, we need to scale value
                // to show up right
                self.gyroXLabel.text = "X = \(obj.x)"
                self.gyroYLabel.text = "Y = \(obj.y)"
                self.gyroZLabel.text = "Z = \(obj.z)"
                self.gyroTimestampLabel.text = "\(obj.timestamp)"
//                array.append(obj)
                self.gyroData.append(SensorData(x: obj.x, y: obj.y, z: obj.z, timestamp: obj.timestamp))
            }
        }
    }
    
    func gyroscopeStopStream() {
        
        streamingEvents.remove(device.gyro!.dataReadyEvent)
        device.gyro!.dataReadyEvent.stopNotificationsAsync()
    }
    
    
    // MARK: - DFU Service delegate methods
    
    func dfuStateDidChange(to state: DFUState) {
        if state == .completed {
            hud?.mode = .text
            hud?.label.text = "Success!"
            hud?.hide(animated: true, afterDelay: 2.0)
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print("Firmware update error \(error): \(message)")
        
        let alertController = UIAlertController(title: "Update Error", message: "Please re-connect and try again, if you can't connect, try MetaBoot Mode to recover.\nError: \(message)", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        hud?.hide(animated: true)
    }
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        hud?.progress = Float(progress) / 100.0
    }
    
    func logWith(_ level: LogLevel, message: String) {
        if level.rawValue >= LogLevel.application.rawValue {
            print("\(level.name()): \(message)")
        }
    }
    
    func select(_ peripheral:CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> Bool {
        return peripheral.identifier == device.identifier
    }
    
    func filterBy(hint dfuServiceUUID: CBUUID) -> [CBUUID]? {
        return nil
    }
    
    // MARK: - helper methods to analyze sensor data
    func maxIndex(array: [Float]) -> Int {
        var maxIndex:Int = -1
        var maxElement:Float = kCFNumberNegativeInfinity as Float
        for (index, element) in array.enumerated() {
            if element > maxElement {
                maxIndex = index
                maxElement = element
            }
        }
        return maxIndex
    }
    
    func calculateTrainingFeatures(sample: Sample) -> [Float] {
        var features = [Float]()
        
        features = calculateRMS(sample: sample, instance: features)
        features = calculateSTDandMean(sample: sample, instance: features)
        features = calculateEnergy(sample: sample, instance: features)
        features = calculateCorrelation(sample: sample, instance: features)
        features = calculateZeroCrossing(sample: sample, instance: features)
        //include ECDF when sample size is small
        features = calculateECDF(sample: sample, instance: features)
        
        return features
    }
    
    func calculateSTDandMean(sample: Sample, instance: [Float]) -> [Float] {
        var accX = [Double]()
        var accY = [Double]()
        var accZ = [Double]()
        var gyroX = [Double]()
        var gyroY = [Double]()
        var gyroZ = [Double]()
        
        for accData in sample.accData {
            accX.append(accData.x)
            accY.append(accData.y)
            accZ.append(accData.z)
        }
        
        for gyroData in sample.gyroData {
            gyroX.append(gyroData.x)
            gyroY.append(gyroData.y)
            gyroZ.append(gyroData.z)
        }
        
        var result = instance
        
        result.append(Float(Sigma.standardDeviationPopulation(accX)!))
        result.append(Float(Sigma.standardDeviationPopulation(accY)!))
        result.append(Float(Sigma.standardDeviationPopulation(accZ)!))
        result.append(Float(Sigma.standardDeviationPopulation(gyroX)!))
        result.append(Float(Sigma.standardDeviationPopulation(gyroY)!))
        result.append(Float(Sigma.standardDeviationPopulation(gyroZ)!))
        
        result.append(Float(Sigma.average(accX)!))
        result.append(Float(Sigma.average(accY)!))
        result.append(Float(Sigma.average(accZ)!))
        result.append(Float(Sigma.average(gyroX)!))
        result.append(Float(Sigma.average(gyroY)!))
        result.append(Float(Sigma.average(gyroZ)!))
        
        return result
    }
    
    func calculateRMS(sample: Sample, instance: [Float]) -> [Float] {
        var accX = Float()
        var accY = Float()
        var accZ = Float()
        var gyroX = Float()
        var gyroY = Float()
        var gyroZ = Float()
        
        for accData in sample.accData {
            accX += Float(accData.x) * Float(accData.x)
            accY += Float(accData.y) * Float(accData.y)
            accZ += Float(accData.z) * Float(accData.z)
        }
        
        for gyroData in sample.gyroData {
            gyroX += Float(gyroData.x) * Float(gyroData.x)
            gyroY += Float(gyroData.y) * Float(gyroData.y)
            gyroZ += Float(gyroData.z) * Float(gyroData.z)
        }
        
        let count = Float(sample.accData.count)
        
        let RMSaccX = accX / count
        let RMSaccY = accY / count
        let RMSaccZ = accZ / count
        let RMSgyroX = gyroX / count
        let RMSgyroY = gyroY / count
        let RMSgyroZ = gyroZ / count
        
        var result = instance
        
        result.append(sqrtf(RMSaccX))
        result.append(sqrtf(RMSaccY))
        result.append(sqrtf(RMSaccZ))
        result.append(sqrtf(RMSgyroX))
        result.append(sqrtf(RMSgyroY))
        result.append(sqrtf(RMSgyroZ))
        
        return result
    }
    
    func calculateEnergy(sample: Sample, instance: [Float]) -> [Float] {
        var accX = Float()
        var accY = Float()
        var accZ = Float()
        var gyroX = Float()
        var gyroY = Float()
        var gyroZ = Float()
        
        for accData in sample.accData {
            accX += Float(accData.x) * Float(accData.x)
            accY += Float(accData.y) * Float(accData.y)
            accZ += Float(accData.z) * Float(accData.z)
        }
        
        for gyroData in sample.gyroData {
            gyroX += Float(gyroData.x) * Float(gyroData.x)
            gyroY += Float(gyroData.y) * Float(gyroData.y)
            gyroZ += Float(gyroData.z) * Float(gyroData.z)
        }
        
        let accEnergy = accX + accY + accZ
        let gyroEnergy = gyroX + gyroY + gyroZ
        
        var result = instance
        
        result.append(accX / accEnergy)
        result.append(accY / accEnergy)
        result.append(accZ / accEnergy)
        result.append(gyroX / gyroEnergy)
        result.append(gyroY / gyroEnergy)
        result.append(gyroZ / gyroEnergy)
        
        return result
    }
    
    func calculateCorrelation(sample: Sample, instance: [Float]) -> [Float] {
        var accX = [Double]()
        var accY = [Double]()
        var accZ = [Double]()
        var gyroX = [Double]()
        var gyroY = [Double]()
        var gyroZ = [Double]()
        
        for accData in sample.accData {
            accX.append(accData.x)
            accY.append(accData.y)
            accZ.append(accData.z)
        }
        
        for gyroData in sample.gyroData {
            gyroX.append(gyroData.x)
            gyroY.append(gyroData.y)
            gyroZ.append(gyroData.z)
        }
        
        var result = instance
        
        result.append(Float(Sigma.pearson(x: gyroX, y: gyroY)!))
        result.append(Float(Sigma.pearson(x: gyroX, y: gyroZ)!))
        result.append(Float(Sigma.pearson(x: gyroY, y: gyroZ)!))
        result.append(Float(Sigma.pearson(x: accX, y: accY)!))
        result.append(Float(Sigma.pearson(x: accX, y: accZ)!))
        result.append(Float(Sigma.pearson(x: accY, y: accZ)!))
        
        return result
    }
    
    func calculateZeroCrossing(sample: Sample, instance: [Float]) -> [Float] {
        var gyroXCrossCount: Float = 0
        var gyroYCrossCount: Float = 0
        var gyroZCrossCount: Float = 0
        
        for i in 0...(sample.gyroData.count - 2) {
            if (sample.gyroData[i].x > 0 && sample.gyroData[i+1].x <= 0) || (sample.gyroData[i].x < 0 && sample.gyroData[i+1].x >= 0) {
                gyroXCrossCount += 1
            }
            if (sample.gyroData[i].y > 0 && sample.gyroData[i+1].y <= 0) || (sample.gyroData[i].y < 0 && sample.gyroData[i+1].y >= 0) {
                gyroYCrossCount += 1
            }
            if (sample.gyroData[i].z > 0 && sample.gyroData[i+1].z <= 0) || (sample.gyroData[i].z < 0 && sample.gyroData[i+1].z >= 0) {
                gyroZCrossCount += 1
            }
        }
        
        var result = instance
        
        result.append(gyroXCrossCount)
        result.append(gyroYCrossCount)
        result.append(gyroZCrossCount)
        
        return result
    }
    
    func calculateECDF(sample: Sample, instance: [Float]) -> [Float] {
        var accX = [Double]()
        var accY = [Double]()
        var accZ = [Double]()
        
        for accData in sample.accData {
            accX.append(accData.x)
            accY.append(accData.y)
            accZ.append(accData.z)
        }
        
        var result = instance
        result = calculateECDFForSingleSetOfData(data: accX, instance: result)
        result = calculateECDFForSingleSetOfData(data: accY, instance: result)
        result = calculateECDFForSingleSetOfData(data: accZ, instance: result)
        
        return result
    }
    
    func calculateECDFForSingleSetOfData(data:[Double], instance: [Float]) -> [Float] {
        //add noise to data
        
        let noise = nextGaussian()
        var noiseData = [Double]()
        for d in data {
            noiseData.append(d+noise)
        }
        noiseData.sort()
        //        let ecdf = ECDF(inputs: noiseData, binCount: 15)
        
        let x = linspace(min: 0, max: 1, points: 15)
        var result = instance
        for f in x {
            //            var cumProb = ecdf.inverseCumulativeProbability(prob: f)
            //            if cumProb == nil {
            //                cumProb = 0
            //            }
            //            result.append(Float(cumProb!))
            result.append(Float(Sigma.quantiles.method1(data, probability: f)!))
        }
        return result
    }
    
    func linspace(min:Double, max:Double, points:Int) -> [Double]{
        var d = [Double]()
        for i in 0...points-1 {
            d.append(min + (Double(i)*(max-min)) / Double(points))
        }
        return d
    }
    
    func nextGaussian() -> Double {
        if let gaussian = nextNextGaussian {
            nextNextGaussian = nil
            return gaussian
        } else {
            var v1, v2, s: Double
            
            repeat {
                v1 = 2 * drand48() - 1
                v2 = 2 * drand48() - 1
                s = v1 * v1 + v2 * v2
            } while s >= 1 || s == 0
            
            let multiplier = sqrt(-2 * log(s)/s)
            nextNextGaussian = v2 * multiplier
            return v1 * multiplier
        }
    }
    
}
