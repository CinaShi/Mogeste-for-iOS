//
//  Ranks.swift
//  SigmaSwiftStatistics
//
//  Created by Alan James Salmoni on 21/01/2017.
//  Copyright © 2017 Evgenii Neumerzhitckii. All rights reserved.
//

import Foundation

public extension Sigma {

  /// Determines how the ranks for the equal values ('ties') are calculated.
  public enum RankTieMethod {
    /**

    Calculates the average rank:

        Sigma.average([100, 100, 100, 100], ties: .average) // [2.5, 2.5, 2.5, 2.5]

    */
    case average

    /**

    Uses the mininum rank:

        Sigma.rank([100, 100, 100, 100], ties: .min) // [1, 1, 1, 1]

    */
    case min

    /**

    Uses the maximum rank:

        Sigma.rank([100, 100, 100, 100], ties: .max) // [4, 4, 4, 4]

    */
    case max

    /**

    Ranks are incremented:

        Sigma.rank([100, 100, 100, 100], ties: .first) // [1, 2, 3, 4]

    */
    case first

    /**

    Ranks are decremented:

        Sigma.rank([100, 100, 100, 100], ties: .last) // [4, 3, 2, 1]

    */
    case last
  }
  
  /**
   
  Returns the ranks of the values in the array.

  - parameter values: Array of decimal numbers.

  - parameter ties: determines how the ranks for the equal values ('ties') are calculated. Default: .average.

  - returns: Returns the ranks of the values in the array.

  Examples:

      Sigma.rank([2, 3, 6, 5, 3]) // [1.0, 2.5, 5.0, 4.0, 2.5]

  */
  public static func rank(_ values: [Double], ties: RankTieMethod = .average) -> [Double] {
    var rank: Double
    let start = 1.0
    
    switch ties {
    case .average:
      rank = start - 0.5
    default:
      rank = start - 1.0
    }
    
    var increment: Double
    var tiny_increment: Double
    let frequencies =  Sigma.frequencies(values)
    
    var ranks = [Double](repeating: 0, count: values.count)
    
    for value in frequencies.keys.sorted() {
      increment = Double(frequencies[value] ?? 1)
      tiny_increment = 1.0
      
      for idx in 0...(values.count - 1) {
        if value == values[idx] {
          switch ties {
          case .average:
            ranks[idx] = rank + (increment / 2.0)
          case .min:
            ranks[idx] = rank + 1
          case .max:
            ranks[idx] = rank + increment
          case .first:
            ranks[idx] = rank + tiny_increment
            tiny_increment += 1
          case .last:
            ranks[idx] = rank + increment - tiny_increment + 1.0
            tiny_increment += 1
          }
        }
      }
      
      rank += increment
    }
    
    return ranks
  }
}
