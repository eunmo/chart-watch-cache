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
    
    // MARK: Notification Key
    
    static let notificationKey = "songNotificationKey"
    
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
    
    func getImageUrl() -> NSURL {
        return Song.DocumentsDirectory.URLByAppendingPathComponent("\(album).jpg")
    }
    
    func saveImage(data: NSData) {
        photo = UIImage(data: data)
        
        let fileUrl = getImageUrl()
        
        data.writeToURL(fileUrl, atomically: true)
        
        print("Saving image to \(fileUrl)")
    }
    
    func load() {
        
        if let filePath = getImageUrl().path where NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            photo = UIImage(contentsOfFile: filePath)
            if (photo != nil) {
                loadMedia()
                return
            }
        }
        
        let urlAsString = "http://39.118.139.72:3000/\(album).80px.jpg"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let query = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            if data != nil {
                self.saveImage(data!)
                self.loadMedia()
            }
        })
        
        query.resume()
    }
    
    func getMediaUrl() -> NSURL {
        return Song.DocumentsDirectory.URLByAppendingPathComponent("\(id).mp3")
    }
    
    func saveMedia(data: NSData) {
        
        let fileUrl = getMediaUrl()
        
        data.writeToURL(fileUrl, atomically: true)
        
        print("Saving media to \(fileUrl)")
    }
    
    func loadMedia() {
        
        if let filePath = getMediaUrl().path where NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            loaded = true
            notify()
            return
        }
        
        let urlAsString = "http://39.118.139.72:3000/music/\(id).mp3"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let query = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            if data != nil {
                self.saveMedia(data!)
                self.loaded = true
                self.notify()
            }
        })
        
        query.resume()
    }
    
    @IBAction func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(Song.notificationKey, object: self)
    }
}