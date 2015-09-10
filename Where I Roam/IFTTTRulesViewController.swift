//
//  IFTTTRulesViewController.swift
//  Where I Roam
//
//  Created by James Lorenzo on 9/9/15.
//  Copyright © 2015 James Lorenzo. All rights reserved.
//

import Foundation
import CoreLocation


class IFTTTRulesViewController: ObservationsViewController
{
    override func showPlacePicker(location: CLLocation)
    {
        let picker = Storyboard.create("placePicker") as! PlacePickerViewController
        picker.currLoc = location
        self.navigationController?.presentViewController(picker, animated: true, completion: nil)
    }
    

}