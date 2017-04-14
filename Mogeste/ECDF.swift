//
//  ECDF.swift
//  Mogeste
//
//  Created by Mengyang Shi on 3/27/17.
//  Copyright © 2017 Mogeste. All rights reserved.
//

import Foundation
import SigmaSwiftStatistics

public final class ECDF {
    
    var inputData:[Double]!
    var binCount:Int!
    var minData:Double!
    var maxData:Double!
    var delta:Double!
    var bins = [[Double]]()
    var upperBounds = [Double]()
    
    var constantRealDistributionValue = 0.0
    
    public init(inputs: [Double], binCount: Int) {
        
        self.inputData = inputs
        self.binCount = binCount
        if binCount < 1 {
            self.binCount = 1
        }
        self.minData = inputs.min()
        self.maxData = inputs.max()
        let delta = (self.maxData - self.minData) / Double(binCount)
        self.delta = delta
        
        for _ in 1...binCount {
            bins.append([Double]())
        }
        
        for data in inputs {
            if data < self.maxData {
                bins[Int((data - self.minData)/delta)].append(data)
            } else {
                bins[binCount-1].append(data)
            }
        }
        
        upperBounds.append(Double(bins[0].count) / Double(inputs.count))
        var previousIndex = 0
        
        while previousIndex < self.binCount - 2 {
            let currentIndex = previousIndex + 1
            upperBounds.append(upperBounds[previousIndex] + Double(bins[currentIndex].count) / Double(inputs.count))
            previousIndex += 1
        }
        
        upperBounds.append(1.0)
        
    }
    
    public func inverseCumulativeProbability(prob:Double) -> Double? {
        
        if prob < 0 || prob > 1 {
            return nil
        }
        
        if prob == 0 {
            return self.minData
        }
        
        if prob == 1 {
            return self.maxData
        }
        
        var selectedIndex = 0
        while self.upperBounds[selectedIndex] < prob {
            selectedIndex += 1
        }
        let selectedStats = bins[selectedIndex]
        let statsMean = Sigma.average(selectedStats)
        let statsSTD = Sigma.standardDeviationPopulation(selectedStats)
        
        //set up binBounds
        var binBounds = [Double]()
        binBounds.append(self.minData + self.delta)
        var previousIndex = 0
        while previousIndex < self.binCount - 2 {
            binBounds.append(binBounds[previousIndex]+self.delta)
            previousIndex += 1
        }
        binBounds.append(self.maxData)
        
        let kB:Double!
        if selectedStats.count == 1 || statsSTD! == 0 {
            //use ConstantRealDistribution
            constantRealDistributionValue = statsMean!
            kB = selectedIndex == 0 ? ConstantRealDistributionCumulativeProbability(x: binBounds[selectedIndex]) - ConstantRealDistributionCumulativeProbability(x: self.minData) : ConstantRealDistributionCumulativeProbability(x: binBounds[selectedIndex]) - ConstantRealDistributionCumulativeProbability(x: binBounds[selectedIndex-1])
        } else {
            kB = selectedIndex == 0 ? Sigma.normalDistribution(x: binBounds[selectedIndex], μ: statsMean!, σ: statsSTD!)! - Sigma.normalDistribution(x: self.minData, μ: statsMean!, σ: statsSTD!)! : Sigma.normalDistribution(x: binBounds[selectedIndex], μ: statsMean!, σ: statsSTD!)! - Sigma.normalDistribution(x: binBounds[selectedIndex-1], μ: statsMean!, σ: statsSTD!)!
        }
        
        let lowerBound = selectedIndex == 0 ? self.minData : binBounds[selectedIndex-1]
        
        let kBminus:Double!
        if selectedStats.count == 1 || statsSTD! == 0 {
            kBminus = ConstantRealDistributionCumulativeProbability(x: lowerBound!)
        } else {
            kBminus = Sigma.normalDistribution(x: lowerBound!, μ: statsMean!, σ: statsSTD!)!
        }
        
        let pB = selectedIndex == 0 ? self.upperBounds[0] :
        self.upperBounds[selectedIndex] - self.upperBounds[selectedIndex-1]
        
        let pBminus = selectedIndex == 0 ? 0 : upperBounds[selectedIndex-1]
        
        let pCrit = prob - pBminus
        
        if pCrit < 0 {
            return lowerBound!
        }
//        print("KB = \(kB)")
//        print("kBminus = \(kBminus)")
//        print("pB = \(pB)")
//        print("pBminus = \(pBminus)")
//        print("prob = \(prob)")
//        print("pCrit = \(pCrit)")
//        print("\(kBminus + pCrit * kB / pB)")
        return Sigma.normalQuantile(p: kBminus + pCrit * kB / pB, μ: statsMean!, σ: statsSTD!)
        
    }
    
    func ConstantRealDistributionCumulativeProbability(x: Double) -> Double {
        return x < constantRealDistributionValue ? 0 : 1
    }
    
}
