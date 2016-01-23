//
//  SongSectionTableViewCell.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 1/23/16.
//  Copyright © 2016 Eunmo Yang. All rights reserved.
//

import UIKit

class SongSectionTableViewCell: UITableViewCell {

    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
