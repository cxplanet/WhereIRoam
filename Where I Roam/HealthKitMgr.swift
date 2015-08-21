//
//  HealthKitMgr.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/17/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitMgr {
 
    let healthKitStore = HKHealthStore()
    
    let stepsCount = HKQuantityType.quantityTypeForIdentifier(
        HKQuantityTypeIdentifierStepCount)
    
//    let stepsSampleQuery = HKSampleQuery(sampleType: stepsCount,
//        predicate: nil,
//        limit: 100,
//        sortDescriptors: nil)
//        { [unowned self] (query, results, error) in
//            if let results = results as? [HKQuantitySample] {
//                self.steps = results
//                self.tableView.reloadData()
//            }
//            self.activityIndicator.stopAnimating()
//    }
//    
//    // Don't forget to execute the Query!
//    healthStore?.executeQuery(stepsSampleQuery)
    
    
    
    
}
