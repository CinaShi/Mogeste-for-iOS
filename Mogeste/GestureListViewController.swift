//
//  GestureListViewController.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/15/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit
import SigmaSwiftStatistics

class GestureListViewController: UITableViewController {
    
    private var nextNextGaussian: Double? = {
        srand48(Int(arc4random())) //initialize drand48 buffer at most once
        return nil
    }()
   
    var userDefaults = UserDefaults.standard
    var newlyAddedSample: Sample?
    var gestures = [Gesture]()
    var selected: [Sample]?
    var trainingInstances = [[Float]]()
    var trainingLabels = [[Float]]()
    
    var startTime: CFAbsoluteTime!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadStoredGestures()
        self.tableView.reloadData()
    }
    
    func loadStoredGestures() {
        if let decoded = userDefaults.object(forKey: "gestures") as? Data {
            gestures = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Gesture]
        }
    }
    
    func updateLocalStorage() {
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: gestures)
        userDefaults.set(encodedData, forKey: "gestures")
        userDefaults.synchronize()
    }
    
    func addSampleToGestureAndReloadTable() {
//        var gestureToTrain:Gesture!
        if gestures.contains(where: {$0.gestureName == newlyAddedSample?.gesture}) {
            for (index, ges) in gestures.enumerated() {
                if ges.gestureName == newlyAddedSample?.gesture {
                    ges.append(sample: newlyAddedSample!)
                    gestures[index] = ges
//                    gestureToTrain = ges
                }
            }
        } else {
            let gid = gestures.count + 1
            let newGesture = Gesture(gestureName: (newlyAddedSample?.gesture)!, samples: [newlyAddedSample!], gid: gid)
            gestures.append(newGesture)
//            gestureToTrain = newGesture
        }
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: gestures)
        userDefaults.set(encodedData, forKey: "gestures")
        userDefaults.synchronize()
        self.tableView.reloadData()
        
//        DispatchQueue.global().async {
//            self.trainGesture(gesture: gestureToTrain, newSample: self.newlyAddedSample!)
//            DispatchQueue.main.async(execute: {
//                self.tableView.reloadData()
//            })
//        }
        
    }
    
    func trainGesture(gesture: Gesture, newSample: Sample) {
        var gestureTrainInstances = [[Float]]()
        var gestureTrainLabels = [[Float]]()
        
        for sample in gesture.samples{
            gestureTrainInstances.append(calculateTrainingFeatures(sample: sample))
            gestureTrainLabels.append([1.0])
        }
        //use neural nets as classifier
        do {
            var network = FFNN.fromFile(filename: "\(gesture.gestureName)_NN")
            startTime = CFAbsoluteTimeGetCurrent()
            if network != nil {
                print("update network started")
                //update network with new input
                let _: [Float] = try network!.update(inputs: calculateTrainingFeatures(sample: newlyAddedSample!))
                
                let _: Float = try network!.backpropagate(answer: [1.0])
                print("update network done")
            } else {
                //set up new network
                print("add network started")
                let featureAmount = gestureTrainInstances.first!.count
                
                network = FFNN(inputs: featureAmount, hidden: featureAmount / 2, outputs: 1, learningRate: 0.001, momentum: 0.4, weights: nil, activationFunction : .Sigmoid, errorFunction: .Default(average: false))
                
                _ = try network?.train(inputs: gestureTrainInstances, answers: gestureTrainLabels, testInputs: gestureTrainInstances, testAnswers: gestureTrainLabels, errorThreshold: 0.2)
                print("add network done")
            }
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("trained \(gesture.gestureName!) in \(elapsed) seconds.")
            network?.writeToFile(filename: "\(gesture.gestureName)_NN")
        } catch {
            print("error occured!")
            print("\(error.localizedDescription)")
        }
        
    }
    
    @IBAction func unwindToDeviceDetailVC(segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? DeviceDetailViewController {
            newlyAddedSample = sourceViewController.newSample
//            print("checkpoint1")
            addSampleToGestureAndReloadTable()
//            print("sample belongs to gesture \(newlyAddedSample!.gesture)")
        }
    }
    
    @IBAction func unwindFromSampleDeletionToZero(segue: UIStoryboardSegue) {
        if segue.source is GestureSamplesTableViewController {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func trainSelectedGestures(_ sender: Any) {
        trainingInstances.removeAll()
        trainingLabels.removeAll()
        if gestures.count > 0 {
            var selectedGestures = [Gesture]()
            var gestureNames = [String]()
            for gesture in gestures {
                if gesture.gestureName == "train1" || gesture.gestureName == "train2" || gesture.gestureName == "train3" {
                    selectedGestures.append(gesture)
                    if !gestureNames.contains(gesture.gestureName) {
                        gestureNames.append(gesture.gestureName)
                    }
                }
            }
            print("gesture names ---> \(gestureNames)")
            
            if selectedGestures.count > 0 {
                
                var trainingSamples = [Sample]()
                for gesture in selectedGestures {
                    for sample in gesture.samples {
                        trainingSamples.append(sample)
                    }
                }
                
                
                if trainingSamples.count > 0 {
                    //compute all features from samples
                    for sample in trainingSamples {
                        
                        trainingInstances.append(calculateTrainingFeatures(sample: sample))
                        var currentLabel = [Float](repeating: 0, count: gestureNames.count)
                        let labelIndex = gestureNames.index(of: sample.gesture)!
                        currentLabel[labelIndex] = 1
                        trainingLabels.append(currentLabel)
                    }
                    
                    let featureAmount = trainingInstances.first!.count
                    
//                    print("training instances ---> \(trainingInstances)")
                    print("training instances feature # ---> \(featureAmount)")
                    print("training labels ---> \(trainingLabels)")
                    //set up test data
//                    var testInstances = [[Float]]()
//                    var testLabels = [[Float]]()
//                    
//                    
//                    
//                    testInstances.append(trainingInstances.first!)
//                    testInstances.append(trainingInstances[6])
//                    testInstances.append(trainingInstances[12])
//                    testLabels.append(trainingLabels.first!)
//                    testLabels.append(trainingLabels[6])
//                    testLabels.append(trainingLabels[12])
//                    
//                    print("testing instances ---> \(testInstances)")
//                    print("testing labels ---> \(testLabels)")
                    
                    //set up neural network
                    startTime = CFAbsoluteTimeGetCurrent()
                    
                    //use neural nets as classifier
                    let network = FFNN(inputs: featureAmount, hidden: featureAmount * 2 / 3, outputs: gestureNames.count, learningRate: 0.008, momentum: 0.1, weights: nil, activationFunction : .HyperbolicTangent, errorFunction: .Default(average: true))
                    do {
                        _ = try network.train(inputs: trainingInstances, answers: trainingLabels, testInputs: trainingInstances, testAnswers: trainingLabels, errorThreshold: 0.06)
//                        print("weights -> \(weights)")
                        for gesture in gestures {
                            if gesture.gestureName == "test" {
                                var sampleNumber = 1
                                for testSample in gesture.samples {
                                    let output:[Float] = try network.update(inputs: calculateTrainingFeatures(sample: testSample))
//                                    print(calculateTrainingFeatures(sample: testSample))
                                    print(output)
                                    let predictedIndex = maxIndex(array: output)
                                    if predictedIndex >= 0 {
                                        print("test sample \(sampleNumber) predicted ---> \(gestureNames[predictedIndex])")
                                        sampleNumber += 1
                                    } else {
                                        print("some errors happen")
                                        break
                                    }
                                }
                                break
                            }
                        }

                        
                        
                    } catch {
                        print(error)
                    }
                    
                    //use SVM as classifier
//                    let trainingInput = YCDataframe()
//                    let trainingOutput = YCDataframe()
//                    
//                    for (index,instance) in trainingInstances.enumerated() {
//                        trainingInput.addSamples(withData: instance)
//                        trainingOutput.addSamples(withData: trainingLabels[index])
//                    }
//                    
//                    let trainer = YCSMORegressionTrainer()
//                    
//                    let model = trainer.train(nil, input: trainingInput, output: trainingOutput)
//                    
//                    let testInput = YCDataframe()
//                    
//                    for gesture in gestures {
//                        if gesture.gestureName == "test" {
//                            for testSample in gesture.samples {
//                                testInput.addSamples(withData: calculateTrainingFeatures(sample: testSample))
//                            }
//                            break
//                        }
//                    }
//                    
//                    let prediction = model?.activate(with: testInput)
//                    print(prediction ?? "error")
                    
                    let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("trained multiple gestures in \(elapsed) seconds.")
                }
                
            } else {
                print("no training sets available!")
            }
        } else {
            print("currently no gestures!")
        }
    }
    
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
    
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gestures.count 
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gestureCell", for: indexPath)

        // Configure the cell...
        let cur = gestures[indexPath.row]
        
        let name = cell.viewWithTag(1) as! UILabel
        name.text = cur.gestureName
        
        let sampleSize = cell.viewWithTag(2) as! UILabel
        sampleSize.text = "\(cur.samplesCount())"
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selected = gestures[indexPath.row].samples
        performSegue(withIdentifier: "gestureSamples", sender: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gestureSamples"{
            let destination = segue.destination as! GestureSamplesTableViewController
            destination.samples = selected!
        } else if segue.identifier == "addNewGesture" {
            let destination = segue.destination as! MetawearTableViewController
            destination.VCsourceIdentifier = "gestureList"
        }
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            gestures.remove(at: indexPath.row)
            updateLocalStorage()
            tableView.reloadData()
        }
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
