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
        setupMotionManager()
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
    
    func updateExistingVisitEvent(visitData : VisitEvent)
    {
        var fetchResults : [VisitEvent];
        
        let fetchRequest = NSFetchRequest(entityName: "VisitEvent")
        let predicate = NSPredicate(format: "arrival == %@", visitData.arrival)
        fetchRequest.predicate = predicate
        do {
            fetchResults = try self.dataHelper!.managedObjectContext!.executeFetchRequest(fetchRequest) as! [VisitEvent]
            if let _ = fetchResults.first
            {
                print("retrieved visit")
            } else {
                print("**** unable to retrieve visit")
            }
            self.dataHelper!.saveContext(self.dataHelper!.backgroundContext!)
            
        } catch let fetchError as NSError {
            print("unable to update existing visit event error: \(fetchError.localizedDescription)")
        }
    }
    
    func updateExistingVisit(visitData : CLVisit)
    {
        var fetchResults : [VisitEvent];
        
        let fetchRequest = NSFetchRequest(entityName: "VisitEvent")
        let predicate = NSPredicate(format: "arrival == %@", visitData.arrivalDate)
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
        if CMMotionActivityManager.isActivityAvailable()
        {
//            self.motionManager.startActivityUpdatesToQueue(motionQueue) { (activity: CMMotionActivity!) -> Void in
//                if activity.walking {
//                    NSLog("We be walking")
//                }
//            }
        }
    }
    
    func dumpVisitEventData()
    {
        var fetchResults : [VisitEvent];
        
        let fetchRequest = NSFetchRequest(entityName: "VisitEvent")
        do {
            fetchResults = try self.dataHelper!.managedObjectContext!.executeFetchRequest(fetchRequest) as! [VisitEvent]
            for visitObj in fetchResults {
                let visit = visitObj as VisitEvent
                print("[\"\(visit.arrival)\", \"\(visit.departure)\", \"\(visit.latitude.doubleValue)\", \"\(visit.longitude.doubleValue)\", \(visit.addressInfo.debugDescription)],")
                updateExistingVisitEvent(visit)
            }
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
        ["2015-08-17 01:28:19 +0000", "2015-08-17 02:32:27 +0000", "41.0832707677918", "-72.3781232626969", "2955 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-17 02:45:12 +0000", "2015-08-17 13:47:25 +0000", "41.0832587355634", "-72.3779274002035", "3085 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-17 14:27:27 +0000", "2015-08-17 14:54:50 +0000", "41.0832023313271", "-72.3781874116025", "3070 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-17 15:22:43 +0000", "2015-08-17 17:58:23 +0000", "41.0832622926889", "-72.378009936506", "3085 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-17 18:44:01 +0000", "2015-08-17 19:35:27 +0000", "41.0832167250157", "-72.3780955959", "3070 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-17 19:53:00 +0000", "2015-08-17 23:29:25 +0000", "41.0832376520648", "-72.3779646516115", "3085 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-17 23:53:23 +0000", "2015-08-18 00:56:14 +0000", "41.0914660739836", "-72.3900960990243", "69405 Main Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-18 01:00:07 +0000", "2015-08-18 12:01:18 +0000", "41.0832013040669", "-72.3779148318652", "3085 Bay Shore Rd\nSouthold‎ NY‎ 11944\nUnited States"],
        ["2015-08-18 19:02:24 +0000", "2015-08-18 19:18:03 +0000", "40.7492303043066", "-73.3235372123694", "20-74 Deer Park Ave\nBabylon‎ NY‎ 11703\nUnited States"],
        ["2015-08-18 20:04:52 +0000", "2015-08-18 20:23:57 +0000", "40.6609611069653", "-73.8033976396517", "Rental Car N\nNew York‎ NY‎ 11430\nUnited States"],
        ["2015-08-18 20:31:55 +0000", "2015-08-18 21:00:12 +0000", "40.6440814192099", "-73.7825276985075", "New York‎ NY‎ 11430\nUnited States"],
        ["2015-08-19 15:30:33 +0000", "2015-08-19 15:39:03 +0000", "47.6914705160299", "-122.359074472951", "8501 1st Ave NW\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-19 15:47:14 +0000", "2015-08-19 20:57:28 +0000", "47.6885035409204", "-122.37372106727", "1319 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-19 21:08:39 +0000", "2015-08-19 21:18:57 +0000", "47.6954379652537", "-122.377707561924", "9205 15th Ave NW\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-19 21:26:33 +0000", "2015-08-20 01:56:36 +0000", "47.688610124348", "-122.373824749076", "1325 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-20 02:10:41 +0000", "2015-08-20 02:59:51 +0000", "47.6884625418952", "-122.373590308656", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-20 16:36:34 +0000", "2015-08-21 00:51:56 +0000", "47.5980697733488", "-122.32856475931", "505 5th Ave S\nSeattle‎ WA‎ 98104\nUnited States"],
        ["2015-08-21 01:34:51 +0000", "2015-08-21 15:49:49 +0000", "47.6886024773034", "-122.373608819182", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-21 16:48:29 +0000", "2015-08-22 00:49:11 +0000", "47.5980738", "-122.328546152838", "505 5th Ave S\nSeattle‎ WA‎ 98104\nUnited States"],
        ["2015-08-22 01:24:33 +0000", "2015-08-22 01:37:22 +0000", "47.6760053", "-122.376127774147", "1500–1516 NW 65th St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 01:45:07 +0000", "2015-08-22 01:55:22 +0000", "47.688482", "-122.373536197687", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 02:04:51 +0000", "2015-08-22 02:21:11 +0000", "47.6951961", "-122.378354259348", "9205 15th Ave NW\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 02:27:54 +0000", "2015-08-22 03:31:07 +0000", "47.688482", "-122.373603914338", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 03:43:25 +0000", "2015-08-22 03:54:07 +0000", "47.691511", "-122.359142154257", "8501 1st Ave NW\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 04:00:30 +0000", "2015-08-22 15:40:36 +0000", "47.688482", "-122.373541950279", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 15:44:53 +0000", "2015-08-22 17:14:57 +0000", "47.6951961", "-122.378151669511", "9205 15th Ave NW\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-22 17:20:53 +0000", "2015-08-23 04:02:40 +0000", "47.688482", "-122.373602903117", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-23 04:11:22 +0000", "2015-08-23 04:21:15 +0000", "47.681291", "-122.355249105306", "7206 Greenwood Ave N\nSeattle‎ WA‎ 98103\nUnited States"],
        ["2015-08-23 04:28:50 +0000", "2015-08-23 19:44:52 +0000", "47.688482", "-122.373629883839", "1319 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-23 19:46:45 +0000", "2015-08-23 21:05:18 +0000", "47.688482", "-122.373504633955", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-23 21:16:41 +0000", "2015-08-23 21:29:58 +0000", "47.6694491", "-122.374532925393", "1400 NW 56th St\nSeattle‎ WA‎ 98107\nUnited States"],
        ["2015-08-23 21:39:43 +0000", "2015-08-24 13:47:04 +0000", "47.688482", "-122.373649938251", "1319 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-24 13:57:03 +0000", "2015-08-24 15:11:07 +0000", "47.688482", "-122.373349191395", "1309 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-24 15:50:42 +0000", "2015-08-25 00:38:08 +0000", "47.5980554611591", "-122.328557224136", "505 5th Ave S\nSeattle‎ WA‎ 98104\nUnited States"],
        ["2015-08-25 00:40:04 +0000", "2015-08-25 00:48:46 +0000", "47.5958683381057", "-122.327255237306", "514 S Dearborn St\nSeattle‎ WA‎ 98104\nUnited States"],
        ["2015-08-25 01:14:42 +0000", "4001-01-01 00:00:00 +0000", "47.6883741316017", "-122.373733455565", "1319 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-25 02:10:23 +0000", "4001-01-01 00:00:00 +0000", "47.6887244163182", "-122.373565203191", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-25 03:01:11 +0000", "2015-08-25 03:15:11 +0000", "47.6840789002794", "-122.383350307216", "2101 NW 77th St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-25 03:19:23 +0000", "4001-01-01 00:00:00 +0000", "47.6886402195891", "-122.373642881869", "1319 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-25 14:36:01 +0000", "4001-01-01 00:00:00 +0000", "47.7026331467949", "-122.363202288361", "431 NW 100th Pl\nSeattle‎ WA‎ 98177\nUnited States"],
        ["2015-08-25 14:54:28 +0000", "4001-01-01 00:00:00 +0000", "47.6884831726173", "-122.373449194702", "1315 NW 83rd St\nSeattle‎ WA‎ 98117\nUnited States"],
        ["2015-08-25 16:24:46 +0000", "4001-01-01 00:00:00 +0000", "47.5980642389237", "-122.328561693772", "505 5th Ave S\nSeattle‎ WA‎ 98104\nUnited States"]]
}
