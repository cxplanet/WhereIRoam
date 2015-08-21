//
//  Observation.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/17/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

@objc(Observation)
class Observation: NSManagedObject {

    
    @NSManaged var latitude: NSNumber!
    @NSManaged var longitude: NSNumber!
    @NSManaged var altitude: NSNumber!
    @NSManaged var timestamp: NSDate!
    @NSManaged var horizontalAccuracy: NSNumber
    @NSManaged var verticalAccuracy: NSNumber
    @NSManaged var speed: NSNumber
    @NSManaged var course: NSNumber
    
    func initFromLocation(location: CLLocation) {
        self.latitude           = location.coordinate.latitude
        self.longitude          = location.coordinate.longitude
        self.altitude           = location.altitude
        self.timestamp          = location.timestamp
        
        self.horizontalAccuracy = location.horizontalAccuracy + 0.0 > 0.0 ? location.horizontalAccuracy : 0.0
        self.verticalAccuracy   = location.verticalAccuracy + 0.0 > 0.0 ? location.verticalAccuracy : 0.0
        self.speed              = location.speed + 0.0 > 0.0 ? location.speed : 0.0
        self.course             = location.course + 0.0 > 0.0 ? location.course : 0.0
    }
    
    func location() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: self.latitude.doubleValue,
                longitude: self.longitude.doubleValue),
                altitude: self.altitude.doubleValue,
                horizontalAccuracy: self.horizontalAccuracy.doubleValue,
                verticalAccuracy: self.verticalAccuracy.doubleValue,
                course: self.course.doubleValue,
                speed: self.speed.doubleValue,
                timestamp: self.timestamp
        )
    }
}
