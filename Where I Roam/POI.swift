//
//  POI.swift
// 'Place of Interest' is a location that is of interest
// to a user. It is geofenced so that arrive and departure rules
// can be specified
//  Where I Roam
//
//  Created by James Lorenzo on 8/7/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

enum Type: Int {
    case HOME=1, WORK, RESTAURANT, FUEL, SPORT, PARK, RELIGION, TRANSPORTATION
}

@objc(POI)
class POI: NSManagedObject
{
    @NSManaged var poiName: String!
    @NSManaged var longitude: NSNumber!
    @NSManaged var latitude: NSNumber!
    @NSManaged var geoFenceRadius: NSNumber!
    @NSManaged var poiType: NSNumber!
    
}