//
//  PlacePicker.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/27/15.
//  Copyright © 2015 James Lorenzo. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import QuadratTouch

typealias JSONParameters = [String: AnyObject]

class PlacePickerViewController : UITableViewController
{
    @IBOutlet weak var cancelButton: UIButton?
    var currLoc: CLLocation?
    var places: [[String: AnyObject]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Place Picker"
        
        // add cancel function
        cancelButton?.addTarget(self, action: Selector("doCancel"), forControlEvents: .TouchUpInside)
        
        if (currLoc != nil) {
            fetchPlaces(currLoc!)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if places?.count > 0 {
            return (places?.count)!
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("placePickerCell", forIndexPath: indexPath)
            as! PlacePickerTableViewCell
        let item = self.places![indexPath.row] as JSONParameters!
        self.configureCellWithItem(cell, item: item)
        return cell
    }
    
    func configureCellWithItem(cell:PlacePickerTableViewCell, item: JSONParameters) {

    }
    
    func fetchPlaces(location: CLLocation) {
        // subclasses
    }
    
    func doCancel(sender: UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

class FourSquarePlacePickerController: PlacePickerViewController
{
    var session: Session!
    
    override func fetchPlaces(location: CLLocation) {
        session = Session.sharedSession()
        let parameters = location.parameters()
        let task = self.session.venues.explore(parameters) {
            (result) -> Void in
            if self.places != nil {
                return
            }
            if !NSThread.isMainThread() {
                fatalError("!!!")
            }
            
            if result.response != nil {
                if let groups = result.response!["groups"] as? [[String: AnyObject]]  {
                    var venues = [[String: AnyObject]]()
                    for group in groups {
                        print(group.debugDescription)
                        if let items = group["items"] as? [[String: AnyObject]] {
                            venues += items
                        }
                    }
                    self.places = venues
                }
                self.tableView.reloadData()
            } else if result.error != nil && !result.isCancelled() {
                NSLog("Error retrieving venues:%@", result.error!)
            }
        }
        task.start()
    }
    
    override func configureCellWithItem(cell:PlacePickerTableViewCell, item: JSONParameters) {
        let venueInfo = item["venue"] as? JSONParameters
        if venueInfo != nil {
            cell.venueNameLabel.text = venueInfo!["name"] as? String
        }
        let refId = item["referralId"]
        if refId != nil {
            cell.venueRefId.text = refId as? String
        }
    }
    
}

class GooglePlacePickerController: PlacePickerViewController
{
    
}

class PlacePickerTableViewCell: UITableViewCell
{
    @IBOutlet weak var venueNameLabel: UILabel!
    @IBOutlet weak var venueRefId: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

// this was part of the das-quadrat demo used for simplifying access to das-quadrat api
extension CLLocation {
    func parameters() -> Parameters {
        let ll      = "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        let llAcc   = "\(self.horizontalAccuracy)"
        let alt     = "\(self.altitude)"
        let altAcc  = "\(self.verticalAccuracy)"
        let parameters = [
            Parameter.ll:ll,
            Parameter.llAcc:llAcc,
            Parameter.alt:alt,
            Parameter.altAcc:altAcc
        ]
        return parameters
    }
}
