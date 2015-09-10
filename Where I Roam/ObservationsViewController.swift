//
//  ObservationsViewController.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/21/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class ObservationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataHelper : CoreDataHelper?
    var currLocation : CLLocation?
    var hasShownUser = false
    var refreshControl : UIRefreshControl?
    var currIndexPath: NSIndexPath?
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("VisitEvent", inManagedObjectContext: dataHelper!.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 50
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "arrival", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        // TODO - get a good caching strategy in place. I'm omitting it for right now
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataHelper!.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = "Visits"
        
        // translucent navbar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true;
        self.navigationController?.view.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor();
        //self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: , target: <#T##AnyObject?#>, action: <#T##Selector#>)
        
        // refresh support
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)

        // core data context is held by appdelegate
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        self.dataHelper = appDelegate!.cdh
        
        setupMapview()
    }
    
    func setupMapview()
    {
        // mapview delegation
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    func addRadiusOverlayForGeoFence(location: CLLocation){
        mapView.addOverlay(MKCircle(centerCoordinate: location.coordinate, radius: 100))
    }

    // XXX old school way to resize. Need to see if there is a better way in iOS7 and above
//    internal func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        if self.currIndexPath == indexPath {
//            return 200;
//        }
//        return 64;
//    }
    
    // MARK: TableView Data Source
    internal func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VisitEventCell", forIndexPath: indexPath) as! VisitEventCell
        let obsItem = fetchedResultsController.objectAtIndexPath(indexPath) as! VisitEvent
        let arrivalTime = NSDateFormatter.localizedStringFromDate(obsItem.arrival, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        if obsItem.departure.isEqualToDate(NSDate.distantFuture()) == false {
            cell.visitDateLabel?.text = String(format: "Arrived %@, stayed %@", arguments: [arrivalTime, StringUtils.convertTimeIntervalToHoursMinutes(obsItem.visitIntervalInSeconds())])
        } else {
            cell.visitDateLabel?.text = String(format: "Arrived %@", arguments: [arrivalTime])
        }
        cell.addressInfoLabel?.text = obsItem.addressInfo
        return cell
    }
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let obsItem = fetchedResultsController.objectAtIndexPath(indexPath) as! VisitEvent
        let coor = CLLocation(latitude: obsItem.latitude.doubleValue, longitude: obsItem.longitude.doubleValue)
        updateMapView(coor)
        // XXX TODO - re-enable this code 
//        if obsItem.hasPlace() {
//            showVisitDetails(obsItem)
//        } else {
//            showPlacePicker(coor)
//        }
//        self.currIndexPath = indexPath
//        self.tableView.beginUpdates()
//        self.tableView.endUpdates()
    }
    
    internal func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] 
            return currentSection.name
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let obsItem = fetchedResultsController.objectAtIndexPath(indexPath)
            self.dataHelper!.managedObjectContext!.deleteObject(obsItem as! NSManagedObject)
            self.dataHelper!.saveContext(self.dataHelper!.managedObjectContext!)
        }
    }
    
    func showVisitDetails(visit: VisitEvent) {
        
        
    }
    
    func showPlacePicker(location: CLLocation)
    {
        let picker = Storyboard.create("placePicker") as! PlacePickerViewController
        picker.currLoc = location
        self.navigationController?.presentViewController(picker, animated: true, completion: nil)
    }
    
    func refresh(sender:AnyObject)
    {
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.reloadData()
    }
    
    // todo - remove this functionality, it's going to drain the battery
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        currLocation = userLocation.location
        let latDelta:CLLocationDegrees = 0.01
        let longDelta:CLLocationDegrees = 0.01
        
        let theSpan = MKCoordinateSpanMake(latDelta, longDelta)
        let pointLocation = userLocation.location!.coordinate
        if hasShownUser == false
        {
            let region:MKCoordinateRegion = MKCoordinateRegionMake(pointLocation, theSpan)
            mapView.setRegion(region, animated: true)
            hasShownUser = true
        }
    }
    
    func updateMapView(userLocation: CLLocation!)
    {
        mapView.removeAnnotations(mapView.annotations)
        let latDelta:CLLocationDegrees = 0.01
        let longDelta:CLLocationDegrees = 0.01
        
        let theSpan = MKCoordinateSpanMake(latDelta, longDelta)
        let pointLocation = userLocation.coordinate
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(pointLocation, theSpan)
        
        // set an annotation
        let myMapPin = MKPointAnnotation();
        myMapPin.coordinate = pointLocation;
        mapView.addAnnotation(myMapPin)
        mapView.setRegion(region, animated: true)
        let selectedRow = tableView.indexPathForSelectedRow
        tableView.deselectRowAtIndexPath(selectedRow!, animated: true)
    }
}

class VisitEventCell : UITableViewCell {
    
    @IBOutlet var visitTimeRangeLabel : UILabel?
    @IBOutlet var visitDateLabel : UILabel?
    @IBOutlet var addressInfoLabel : UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentView.layer.cornerRadius = 5.0
        self.contentView.layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

class Storyboard: UIStoryboard {
    class func create(name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(name)
    }
}