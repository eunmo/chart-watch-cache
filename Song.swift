//
//  Song.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/21/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit


class Song: NSObject, NSCoding {
    
    // MARK: Properties
    
    var name: String
    var photo: UIImage?
    var artist: String
    var id: Int
    var album: Int
    var loaded: Bool
    
    // MARK: Types
    
    struct PropertyKey {
        static let nameKey = "name"
        static let artistKey = "artist"
        static let IdKey = "songId"
        static let albumKey = "album"
    }
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("songs")
    
    init?(name: String, artist: String, id: Int, album: Int) {
        // Initialize stored properties.
        self.name = name
        self.artist = artist
        self.photo = nil
        self.id = id;
        self.album = album;
        self.loaded = false;
        
        super.init()
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty {
            return nil
        }
    }
    
    // MARK: NSCoding
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: PropertyKey.nameKey)
        aCoder.encodeObject(artist, forKey: PropertyKey.artistKey)
        aCoder.encodeInteger(id, forKey: PropertyKey.IdKey)
        aCoder.encodeInteger(album, forKey: PropertyKey.albumKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObjectForKey(PropertyKey.nameKey) as! String
        let artist = aDecoder.decodeObjectForKey(PropertyKey.artistKey) as! String
        let id = aDecoder.decodeIntegerForKey(PropertyKey.IdKey)
        let album = aDecoder.decodeIntegerForKey(PropertyKey.albumKey)
        
        self.init(name: name, artist: artist, id: id, album: album)
    }
}