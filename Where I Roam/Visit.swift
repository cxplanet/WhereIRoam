//
//  VisitObservation.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/3/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//


import Foundation
import CoreData
import CoreLocation
@objc(Place)
class VisitEvent: NSManagedObject {
    
    @NSManaged var latitude: NSNumber!
    @NSManaged var longitude: NSNumber!
    @NSManaged var altitude: NSNumber!
    @NSManaged var startTime: NSDate!
    @NSManaged var horizontalAccuracy: NSNumber
    @NSManaged var verticalAccuracy: NSNumber
    @NSManaged var id: String!
    @NSManaged var name: String!
    @NSManaged var desc: String!

}
