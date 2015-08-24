//
//  RoamingManager.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/27/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import AddressBookUI //address format
import Foundation
import CoreLocation
import CoreMotion
import CoreData
import UIKit

// Capture observations from the device
// todo:
public class RoamingMgr: NSObject, CLLocationManagerDelegate{
    
    // XXX move this to a struct. This is a simple filter to 
    // minimize duplicate readings near term - we need to move at least
    // 1 meter for an observation to be recorded.
    let ACTIVE_ROAMING_THRESHOLD = 5.0 // meters
    let HORIZONTAL_OBSERVATION_ACCURACY = 10.0
    
    // singleton in Swift (much like the Java approach)
    static let sharedInstance = RoamingMgr()
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionActivityManager()
    let motionQueue = NSOperationQueue()
    
    let geoCoder = CLGeocoder()
    
    var currLocation : CLLocation?
    var currActivity : CLActivityType?
    var dataHelper : CoreDataHelper?
    var appDelegate : AppDelegate? 
    
    override init() {
        
        super.init()
        
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        self.dataHelper = appDelegate!.cdh
        
        let notificationSettings = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
        setupLocationManager()
        dumpVisitEventData()
    }
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization() // hopefully not a loop...
            break
        case .AuthorizedWhenInUse, .AuthorizedAlways:
//            if UIApplication.sharedApplication().applicationState == UIApplicationState.Background
//            {
//                enableBackgroundMode()
//            }
//            else
//            {
//                enableForegroundMode()
//            }
            enableBackgroundMode()
            break
        case .Restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            break
        case .Denied:
            // user denied your app access to Location Services, but can grant access from Settings.app
            let alert = UIAlertController(title: "Location Services disabled", message: "Please enable Location Services in Settings if you wish to record the places you travel to", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            appDelegate!.window!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
            break
        // left out the default, as the compiler warns
        }
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var hasLocationsToStore = false
        for location in locations{
            // only store observations we have some belief in
            let currSampleLoc = location //as? CLLocation

            if currSampleLoc.horizontalAccuracy > HORIZONTAL_OBSERVATION_ACCURACY {
                if self.currLocation == nil || self.currLocation?.distanceFromLocation(currSampleLoc) > ACTIVE_ROAMING_THRESHOLD
                {
                    self.currLocation = currSampleLoc
                    hasLocationsToStore = true
                    NSLog(currLocation.debugDescription)
                    let newObs: Observation = NSEntityDescription.insertNewObjectForEntityForName("Observation", inManagedObjectContext: self.dataHelper!.backgroundContext!) as! Observation
                    newObs.initFromLocation(currSampleLoc)
                }
            }

        }
        if hasLocationsToStore {
            self.dataHelper!.saveContext(self.dataHelper!.backgroundContext!)
        }
    }
    
    // need to determine if this is a viable path
    public func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
        if visit.horizontalAccuracy > HORIZONTAL_OBSERVATION_ACCURACY {
            handleVisitEvent(visit)
        }
    }
    
    func handleVisitEvent(visitData: CLVisit)
    {
        //first fire an event
        let dateTime = NSDate()
        let visitNotify = UILocalNotification()
        visitNotify.alertTitle = "New Visit"
        visitNotify.alertBody = "Data: \(visitData)"
        visitNotify.fireDate = dateTime
        UIApplication.sharedApplication().scheduleLocalNotification(visitNotify)
        createNewVisit(visitData)
        
        
//        if (visitData.departureDate.isEqualToDate(NSDate.distantFuture()))
//        {
//            createNewVisit(visitData)
//        } else
//        {
//            updateExistingVisit(visitData)
//        }
    }
    
    // no departure date, so assume its a new visit
    func createNewVisit(visitData : CLVisit)
    {
        let visitLocation = CLLocation(latitude: visitData.coordinate.latitude, longitude: visitData.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(visitLocation, completionHandler: {(placemarks, error) -> Void in
            if let placemark = placemarks?.first {
                let newVisit: VisitEvent = NSEntityDescription.insertNewObjectForEntityForName("VisitEvent", inManagedObjectContext: self.dataHelper!.backgroundContext!) as! VisitEvent
                newVisit.initFromCLVisit(visitData)
                let address = ABCreateStringWithAddressDictionary(placemark.addressDictionary!, false)
                newVisit.addressInfo = address
                self.dataHelper!.saveContext(self.dataHelper!.backgroundContext!)
            }
            else {
                NSLog("Problem with the data received from geocoder")
            }
        })
    }
    
    func updateExistingVisit(visitData : CLVisit)
    {
        var fetchResults : [VisitEvent];
        
        let fetchRequest = NSFetchRequest(entityName: "VisitEvent")
        let predicate = NSPredicate(format: "arrival contains[search] %@", visitData.arrivalDate)
        fetchRequest.predicate = predicate
        do {
            fetchResults = try self.dataHelper!.managedObjectContext!.executeFetchRequest(fetchRequest) as! [VisitEvent]
            if let visitEvent = fetchResults.first
            {
                visitEvent.departure = visitData.departureDate
            }
            self.dataHelper!.saveContext(self.dataHelper!.backgroundContext!)
            
        } catch let fetchError as NSError {
            print("unable to update existing visit event error: \(fetchError.localizedDescription)")
        }
    }
    
    public func enableBackgroundMode() {
        NSLog("enable background location tracking")
        locationManager.stopUpdatingLocation()
        // filters are not supported in this call
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startMonitoringVisits()
    }
    
    // increase resolution in foreground, in case the user is looking 
    // to accurately identify a POI they are currently at
    public func enableForegroundMode() {
        NSLog("enable foreground location tracking")
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        // todo - based on speed/heading, try to fit an activity profile
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
    }
    
    func setupLocationManager() {
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()        
    }
    
    func setupMotionManager() {
        
//        if CMMotionActivityManager.isActivityAvailable()
//        {
//            self.motionManager.startActivityUpdatesToQueue(motionQueue) { (activity: CMMotionActivity!) -> Void in
//                if activity.walking {
//                    NSLog("We be walking")
//                }
//            }
//        }
    }
    
    func dumpVisitEventData()
    {
        var fetchResults : [VisitEvent];
        
        let fetchRequest = NSFetchRequest(entityName: "VisitEvent")
        do {
            fetchResults = try self.dataHelper!.managedObjectContext!.executeFetchRequest(fetchRequest) as! [VisitEvent]
            for visitObj in fetchResults {
                let visit = visitObj as VisitEvent
                let today = NSDate()
                let yesterday = today.dateByAddingTimeInterval(-6 * 60 * 60)
                if visit.departure.isEqualToDate(NSDate.distantFuture()) && visit.arrival.timeIntervalSinceDate(yesterday) < 0 {
                    print("User arrived, but has not left:")
                    print(visit.debugDescription)
        //            self.dataHelper!.managedObjectContext!.deleteObject(visitObj)
                }
//                    else {
                    print(visit.debugDescription)
//                }
            }
      //     self.dataHelper!.saveContext(self.dataHelper!.managedObjectContext!)
            print("VisitEvent count: \(fetchResults.count)")
        } catch let fetchError as NSError {
            print("getVisitEvents error: \(fetchError.localizedDescription)")
        }
    }
    
    func addVisits() {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        
        if let visit = visits.first{
            let newVisit: VisitEvent = NSEntityDescription.insertNewObjectForEntityForName("VisitEvent", inManagedObjectContext: self.dataHelper!.backgroundContext!) as! VisitEvent
            newVisit.initFromVisitData(visit)
            if let arrDate = formatter.dateFromString(visit[0])
            {
                newVisit.arrival = arrDate
            }
            if let depDate = formatter.dateFromString(visit[1])
            {
                newVisit.departure = depDate
            }
            
            let visitLocation = CLLocation(latitude: newVisit.latitude.doubleValue, longitude: newVisit.longitude.doubleValue)
            geoCoder.reverseGeocodeLocation(visitLocation, completionHandler: {(placemarks, error) -> Void in
                //            if error != nil {
                //                NSLog("Error while geocoding")
                //                return
                //            }
                if let placemark = placemarks?.first {
                    let address = ABCreateStringWithAddressDictionary(placemark.addressDictionary!, false)
                    NSLog(address)
                }
                else {
                    NSLog("Problem with the data received from geocoder")
                }
            })
        }
        
    }
    
    let visits:[[String]] = [
        ["0000-12-30 00:00:00 +0000", "2015-08-04 00:21:06 +0000", "47.598060", "-122.328568"],
        ["2015-08-04 01:04:48 +0000", "4001-01-01 00:00:00 +0000", "47.688503", "-122.373532"],
        ["2015-08-04 01:04:48 +0000", "2015-08-04 14:02:26 +0000", "47.688563", "-122.373555"],
        ["2015-08-04 14:19:07 +0000", "4001-01-01 00:00:00 +0000", "47.688493", "-122.373648"],
        ["2015-08-04 14:19:07 +0000", "2015-08-04 15:42:22 +0000", "47.688562", "-122.373715"],
        ["2015-08-04 16:17:25 +0000", "4001-01-01 00:00:00 +0000", "47.597245", "-122.327952"],
        ["2015-08-04 16:25:36 +0000", "2015-08-05 00:35:33 +0000", "47.598039", "-122.328593"],
        ["2015-08-05 00:48:51 +0000", "4001-01-01 00:00:00 +0000", "47.598634", "-122.328075"],
        ["2015-08-05 00:48:51 +0000", "2015-08-05 00:54:37 +0000", "47.598634", "-122.328075"],
        ["2015-08-05 01:25:06 +0000", "4001-01-01 00:00:00 +0000", "47.688525", "-122.373624"],
        ["2015-08-05 01:25:06 +0000", "2015-08-05 15:46:54 +0000", "47.688539", "-122.373611"],
        ["2015-08-05 16:25:53 +0000", "4001-01-01 00:00:00 +0000", "47.598021", "-122.328598"],
        ["2015-08-05 16:25:53 +0000", "2015-08-06 00:18:01 +0000", "47.598036", "-122.328578"],
        ["2015-08-06 00:18:42 +0000", "4001-01-01 00:00:00 +0000", "47.595980", "-122.326943"],
        ["2015-08-06 00:18:42 +0000", "2015-08-06 00:29:00 +0000", "47.595884", "-122.327591"],
        ["2015-08-06 01:11:19 +0000", "4001-01-01 00:00:00 +0000", "47.688503", "-122.373539"],
        ["2015-08-06 01:11:19 +0000", "2015-08-06 01:54:15 +0000", "47.688475", "-122.373532"],
        ["2015-08-06 05:24:23 +0000", "4001-01-01 00:00:00 +0000", "47.688631", "-122.373515"],
        ["2015-08-06 05:24:23 +0000", "2015-08-06 15:57:08 +0000", "47.688492", "-122.373380"],
        ["2015-08-06 16:36:48 +0000", "4001-01-01 00:00:00 +0000", "47.597987", "-122.328515"],
        ["2015-08-06 16:36:48 +0000", "2015-08-07 00:14:39 +0000", "47.598024", "-122.328599"],
        ["2015-08-07 01:02:12 +0000", "4001-01-01 00:00:00 +0000", "47.688407", "-122.373538"],
        ["2015-08-07 01:02:12 +0000", "2015-08-07 02:53:11 +0000", "47.688444", "-122.373576"],
        ["2015-08-07 03:03:47 +0000", "4001-01-01 00:00:00 +0000", "47.691080", "-122.359466"],
        ["2015-08-07 03:03:47 +0000", "2015-08-07 03:09:28 +0000", "47.691080", "-122.359466"],
        ["2015-08-07 03:15:43 +0000", "4001-01-01 00:00:00 +0000", "47.663554", "-122.370692"],
        ["2015-08-07 03:15:43 +0000", "2015-08-07 03:26:20 +0000", "47.663310", "-122.370816"],
        ["2015-08-07 03:27:10 +0000", "4001-01-01 00:00:00 +0000", "47.660221", "-122.368684"],
        ["2015-08-07 03:27:10 +0000", "2015-08-07 03:37:27 +0000", "47.660291", "-122.368740"],
        ["2015-08-07 03:49:10 +0000", "4001-01-01 00:00:00 +0000", "47.688548", "-122.373490"],
        ["2015-08-07 03:49:10 +0000", "2015-08-07 21:02:32 +0000", "47.688564", "-122.373680"],
        ["2015-08-07 21:04:52 +0000", "4001-01-01 00:00:00 +0000", "47.688971", "-122.376357"],
        ["2015-08-07 21:04:52 +0000", "2015-08-07 21:10:53 +0000", "47.688971", "-122.376357"],
        ["2015-08-07 21:17:44 +0000", "4001-01-01 00:00:00 +0000", "47.660625", "-122.368510"],
        ["2015-08-07 21:17:44 +0000", "2015-08-07 21:27:25 +0000", "47.660584", "-122.368902"],
        ["2015-08-08 01:20:11 +0000", "4001-01-01 00:00:00 +0000", "48.674708", "-121.615117"],
        ["2015-08-08 01:20:11 +0000", "2015-08-08 01:32:06 +0000", "48.674630", "-121.614872"],
        ["2015-08-08 02:40:15 +0000", "4001-01-01 00:00:00 +0000", "48.665960", "-121.585133"],
        ["2015-08-08 02:40:15 +0000", "2015-08-08 16:11:04 +0000", "48.665892", "-121.584969"],
        ["2015-08-08 18:16:55 +0000", "4001-01-01 00:00:00 +0000", "48.672259", "-121.600669"],
        ["2015-08-08 18:16:55 +0000", "2015-08-08 18:37:02 +0000", "48.672266", "-121.600676"],
        ["2015-08-08 18:37:03 +0000", "4001-01-01 00:00:00 +0000", "48.673035", "-121.601257"],
        ["2015-08-08 18:37:03 +0000", "2015-08-08 19:29:03 +0000", "48.673190", "-121.601623"],
        ["2015-08-08 20:48:12 +0000", "4001-01-01 00:00:00 +0000", "48.665814", "-121.584823"],
        ["2015-08-10 17:39:52 +0000", "4001-01-01 00:00:00 +0000", "47.598086", "-122.328534"]]
}
