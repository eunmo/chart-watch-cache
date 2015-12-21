//
//  Song.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/21/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit


class Song {
    
    // MARK: Properties
    
    var name: String
    var photo: UIImage?
    var artist: String
    
    init?(name: String, artist: String, photo: UIImage?) {
        // Initialize stored properties.
        self.name = name
        self.artist = artist
        self.photo = photo
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty {
            return nil
        }
    }
}