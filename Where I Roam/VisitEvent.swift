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
    
    func initFromVisitData(data: [String]!) {
        self.longitude          = (data[3] as NSString).doubleValue
        self.latitude          = (data[2] as NSString).doubleValue
    }
    
//    func initFromArchivedVisitData(data: [String]!) {
//        self.longitude          = (data[3] as NSString).doubleValue
//        self.latitude          = (data[2] as NSString).doubleValue
//    }
//    
    func initFromCLVisit(data: CLVisit!) {
        self.longitude = data.coordinate.longitude
        self.latitude = data.coordinate.latitude
        self.arrival = data.arrivalDate
        self.departure = data.departureDate
    }
    
    func hasArrivalTime() -> Bool{
        return (self.departure.isEqualToDate(NSDate.distantPast()) == false)
    }
    
    func hasDepartureTime() -> Bool{
        return (self.departure.isEqualToDate(NSDate.distantFuture()) == false)
    }
    
    func visitIntervalInSeconds() -> Double
    {
        return self.departure.timeIntervalSinceDate(self.arrival)
    }
    
}
