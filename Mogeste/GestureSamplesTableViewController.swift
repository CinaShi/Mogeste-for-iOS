//
//  GestureSamplesTableViewController.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/17/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit
import SigmaSwiftStatistics

class GestureSamplesTableViewController: UITableViewController {
    
    private var nextNextGaussian: Double? = {
        srand48(Int(arc4random())) //initialize drand48 buffer at most once
        return nil
    }()
    
    var userDefaults = UserDefaults.standard
    var samples: [Sample]!
    var selected: Sample?
    var startTime: CFAbsoluteTime!
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.title = samples.first?.gesture
    }
    
    @IBAction func unwindToCurrentSample(segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? DeviceDetailViewController {
            addSampleToGestureAndReloadTable(newlyAddedSample: sourceViewController.newSample!)
        }
    }
    
    func updateLocalStorage(removeIndex: Int) {
        guard let decoded = userDefaults.object(forKey: "gestures") as? Data else {
            print("error in unarchive gestures")
            return
        }
        var gestures = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Gesture]
        
        var currentGestureIndex = 0
        if gestures.contains(where: {$0.gestureName == titleLabel.title}) {
            for (index, ges) in gestures.enumerated() {
                if ges.gestureName == titleLabel.title {
                    currentGestureIndex = index
                    break
                }
            }
        } else {
            //            print("checkpoint2")
            print("error: gusture doesn't exist!")
        }
        
        let currentGesture = gestures[currentGestureIndex]
        currentGesture.remove(index: removeIndex)
        if currentGesture.samples.count <= 0 {
            gestures.remove(at: currentGestureIndex)
        } else {
            gestures[currentGestureIndex] = currentGesture
        }
        
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: gestures)
        userDefaults.set(encodedData, forKey: "gestures")
        userDefaults.synchronize()
        
        if samples.count <= 0 {
            performSegue(withIdentifier: "allDeleted", sender: self)
        } else {
            tableView.reloadData()
        }
    }
    
    func addSampleToGestureAndReloadTable(newlyAddedSample: Sample) {
        guard let decoded = userDefaults.object(forKey: "gestures") as? Data else {
            print("error in unarchive gestures")
            return
        }
//        var gestureToTrain:Gesture!
        var gestures = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Gesture]
        var currentIndex = 0
        if gestures.contains(where: {$0.gestureName == newlyAddedSample.gesture}) {
            for (index, ges) in gestures.enumerated() {
                if ges.gestureName == newlyAddedSample.gesture {
                    ges.append(sample: newlyAddedSample)
                    gestures[index] = ges
                    currentIndex = index
//                    gestureToTrain = ges
                }
            }
        } else {
//            print("checkpoint2")
            print("error: gusture doesn't exist!")
        }
//        print("checkpoint3")
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: gestures)
        userDefaults.set(encodedData, forKey: "gestures")
        userDefaults.synchronize()
        
        samples = gestures[currentIndex].samples
        self.tableView.reloadData()
//        DispatchQueue.global().async {
//            self.trainGesture(gesture: gestureToTrain, newSample: newlyAddedSample)
//            DispatchQueue.main.async(execute: {
//                self.tableView.reloadData()
//            })
//        }
    }
    


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Samples"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return samples.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sampleCell", for: indexPath)

        // Configure the cell...
        let cur = samples[indexPath.row]
        
        let name = cell.viewWithTag(1) as! UILabel
        name.text = "Sample \(indexPath.row + 1)"
        
        let sampleSize = cell.viewWithTag(2) as! UILabel
        sampleSize.text = "Data size: \(cur.accData.count)"
        
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selected = samples[indexPath.row]
        performSegue(withIdentifier: "sampleDetails", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            samples.remove(at: indexPath.row)
            updateLocalStorage(removeIndex: indexPath.row)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sampleDetails"{
            let destination = segue.destination as! SampleDetailsViewController
            destination.sample = selected!
            destination.sampleTitle = titleLabel.title
        } else if segue.identifier == "addNewSample" {
            let destination = segue.destination as! MetawearTableViewController
            destination.VCsourceIdentifier = "sampleList"
            destination.gestureNameFromSampleList = (samples.first?.gesture)!
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
