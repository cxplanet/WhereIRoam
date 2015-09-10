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

@objc(Place)
class Place: NSManagedObject
{
    @NSManaged var name: String
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var visited: Int32
    
    func initFromPlace(place: Place) {
        self.name = place.name
        self.latitude = place.latitude
        self.longitude = place.longitude
        self.visited = 0
    }
}