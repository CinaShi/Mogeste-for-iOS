//
//  SampleDetailsViewController.swift
//  Mogeste
//
//  Created by Mengyang Shi on 2/17/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import UIKit

class SampleDetailsViewController: UIViewController {

    var sample: Sample!
    var sampleTitle: String!
    
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var accDataSize: UILabel!
    @IBOutlet weak var gyroDataSize: UILabel!
    @IBOutlet weak var accFirstX: UILabel!
    @IBOutlet weak var accFirstY: UILabel!
    @IBOutlet weak var accFirstZ: UILabel!
    @IBOutlet weak var accFirstTimeStamp: UILabel!
    
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleLabel.title = sampleTitle
        
        lengthLabel.text = "Length of sample: \(sample.length)"
        accDataSize.text = "Acc data size: \(sample.accData.count)"
        gyroDataSize.text = "Gyro data size: \(sample.gyroData.count)"
        let firstAccData = sample.accData.first!
        accFirstX.text = "First acc data x: \(firstAccData.x!)"
        accFirstY.text = "First acc data y: \(firstAccData.y!)"
        accFirstZ.text = "First acc data z: \(firstAccData.z!)"
        accFirstTimeStamp.text = "First acc timestamp: \(firstAccData.timestamp!)"
    }

    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
