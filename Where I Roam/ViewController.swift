//
//  ViewController.swift
//  Where I Roam
//
//  Created by James Lorenzo on 7/16/15.
//  Copyright (c) 2015 James Lorenzo. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            self.updateUserLocation()
        }
    }
    
    func updateUserLocation() {
        if let location = RoamingMgr.sharedInstance.currLocation {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            
            self.mapView.setRegion(region, animated: true)
            
            let pinLocation = center
            let objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            self.mapView.addAnnotation(objectAnnotation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

