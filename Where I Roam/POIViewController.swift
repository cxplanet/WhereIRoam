//
//  POIViewController.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/10/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class POIViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataHelper : CoreDataHelper?
    var currLocation : CLLocation?
    var hasShownUser = false
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let observationFetchRequest = NSFetchRequest(entityName: "POI")
        let primarySortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        observationFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let frc = NSFetchedResultsController(
            fetchRequest: observationFetchRequest,
            managedObjectContext: self.dataHelper!.managedObjectContext!,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Places"
        
        // refresh support
        //self.refreshControl!.addTarget(self, action: "refreshObservations", forControlEvents: UIControlEvents.ValueChanged)
        
        // core data context is held by appdelegate
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        self.dataHelper = appDelegate!.cdh

        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    func addRadiusOverlayForGeoFence(location: CLLocation){
        mapView.addOverlay(MKCircle(centerCoordinate: location.coordinate, radius: 100))
    }
    
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
        let cell = tableView.dequeueReusableCellWithIdentifier("ObservationCell", forIndexPath: indexPath) 
        let obsItem = fetchedResultsController.objectAtIndexPath(indexPath) as! Observation
        cell.textLabel!.text = NSDateFormatter.localizedStringFromDate(obsItem.timestamp, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
        cell.detailTextLabel!.text = obsItem.location().description
        return cell
    }
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let obsItem = fetchedResultsController.objectAtIndexPath(indexPath) as! Observation
        let coor = obsItem.location()
        updateMapView(coor)
    }
    
    internal func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] 
            return currentSection.name
        }
        return nil
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        self.tableView.reloadData()
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        // if user location is not nil
        currLocation = userLocation.location
        let latDelta:CLLocationDegrees = 0.01
        let longDelta:CLLocationDegrees = 0.01
        
        let theSpan = MKCoordinateSpanMake(latDelta, longDelta)
        let pointLocation = currLocation?.coordinate
        if hasShownUser == false
        {
            let region:MKCoordinateRegion = MKCoordinateRegionMake(pointLocation!, theSpan)
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