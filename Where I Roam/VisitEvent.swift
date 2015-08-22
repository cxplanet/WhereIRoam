//
//  VisitEvent.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/7/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//
// Visits are typically found from CLVisit, but can also 
// be created by filtering through the Observations taken, and 
// fusing them with the data found in motion sensor activities
// If a visit event occurs more than 5 times, or find that the interval is 
// more than 4 hours, we will prompt the user to confirm whether the
// event is a place we should be aware of.
//

import Foundation
import CoreData
import CoreLocation

@objc(VisitEvent)
class VisitEvent: NSManagedObject
{
    @NSManaged var longitude: NSNumber!
    @NSManaged var latitude: NSNumber!
    @NSManaged var arrival: NSDate
    @NSManaged var departure: NSDate
    @NSManaged var addressInfo: String
    @NSManaged var hasDeparture: Bool
    
//    func initFromVisitData(data: [String]!) {
//        self.longitude          = (data[3] as NSString).doubleValue
//        self.latitude          = (data[2] as NSString).doubleValue
//    }
//    
//    func initFromArchivedVisitData(data: [String]!) {
//        self.longitude          = (data[3] as NSString).doubleValue
//        self.latitude          = (data[2] as NSString).doubleValue
//    }
//    
    func initFromCLVisit(data: CLVisit!) {
        self.longitude = data.coordinate.longitude
        self.latitude = data.coordinate.longitude
        self.arrival = data.arrivalDate
        self.hasDeparture = (self.arrival.timeIntervalSinceDate(self.departure) > 0)
        
    }
    
    func visitIntervalInSeconds() -> Double
    {
        return self.departure.timeIntervalSinceDate(self.arrival)
    }
    
}
