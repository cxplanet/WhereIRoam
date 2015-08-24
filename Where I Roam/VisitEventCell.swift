//
//  VisitCell.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/15/15.
//  Copyright © 2015 James Lorenzo. All rights reserved.
//

import Foundation
import UIKit

class VisitEventCell : UITableViewCell {

    @IBOutlet var arrivalDateLabel : UILabel?
    @IBOutlet var departureDateLabel : UILabel?
    @IBOutlet var addressInfoLabel : UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
