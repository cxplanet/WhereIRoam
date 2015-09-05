//
//  PlacesViewController.swift
//  Where I Roam
//
//  Created by James Lorenzo on 9/4/15.
//  Copyright © 2015 James Lorenzo. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class MyPlacesViewController: ObservationsViewController {
    
    override var fetchedResultsController: NSFetchedResultsController {
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "My Places"
    }
    
}
