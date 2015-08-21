//
//  TransitFilter.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/4/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation
import UIKit

class TransitAnalyzer: NSObject
{
    
    // singleton access
    static let sharedInstance = TransitAnalyzer()
    
    var dataHelper : CoreDataHelper?
    var appDelegate : AppDelegate?
    var currGeoFence: POI?
    
    override init() {
        
        super.init()
        
        self.appDelegate = (UIApplication.sharedApplication().delegate as? AppDelegate)!
        self.dataHelper = appDelegate!.cdh
        
    }
    
//
//    public func identifyVisits(observations: [Observation]!) -> [VisitEvent]
//    {
//
//    }
    
}
