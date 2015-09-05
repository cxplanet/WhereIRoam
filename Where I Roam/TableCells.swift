//
//  VisitCell.swift
//  Where I Roam
//
//  Created by James Lorenzo on 8/15/15.
//  Copyright © 2015 James Lorenzo. All rights reserved.
//

import Foundation
import UIKit

class UserPhotoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    @IBOutlet weak var venueNameLabel: UILabel!
    @IBOutlet weak var venueRatingLabel: UILabel!
    @IBOutlet weak var venueCommentLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userPhotoImageView.layer.cornerRadius = 4
        userPhotoImageView.layer.shouldRasterize = true
        userPhotoImageView.layer.rasterizationScale = UIScreen.mainScreen().scale
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.userPhotoImageView.image = nil
    }
}
