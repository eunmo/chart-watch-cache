//
//  Song.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/21/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit
import MediaPlayer

class Song: NSObject, NSCoding {
    
    // MARK: Properties
    
    var name: String
    var artist: String
    var id: Int
    var album: Int
    var plays: Int
    var lastPlayed: NSDate?
    
    var photo: UIImage?
    var loaded: Bool
    var extractedImage: UIImage?
    
    // MARK: Types
    
    struct PropertyKey {
        static let nameKey = "name"
        static let artistKey = "artist"
        static let IdKey = "songId"
        static let albumKey = "album"
        static let playsKey = "plays"
        static let lastPlayedKey = "lastPlayed"
    }
    
    // MARK: Notification Key
    
    static let notificationKey = "songNotificationKey"
    
    init?(name: String, artist: String, id: Int, album: Int, plays: Int, lastPlayed: NSDate?) {
        // Initialize stored properties.
        self.name = name
        self.artist = artist
        self.id = id
        self.album = album
        self.plays = plays
        self.lastPlayed = lastPlayed
        
        self.photo = nil
        self.loaded = false
        
        super.init()
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty {
            return nil
        }
        
        //print ("\(name) played \(plays) times (last played \(lastPlayed))")
    }
    
    // MARK: Update
    
    func recordPlay() {
        plays++
        lastPlayed = NSDate()
        
        print ("\(name) played \(plays) times (last played \(lastPlayed))")
    }
    
    // MARK: Information
    
    func getNowPlayingInfo() -> [String:AnyObject] {
        let url = getMediaUrl()
        let playerItem = AVPlayerItem(URL: url)  //this will be your audio source
        var nowPlayingInfo:[String: AnyObject] = [
            MPMediaItemPropertyTitle: name,
            MPMediaItemPropertyArtist: artist,
        ]
        
        let metadataList = playerItem.asset.metadata
        for item in metadataList {
            if item.commonKey != nil && item.value != nil {
                if item.commonKey  == "artwork" {
                    if let image = UIImage(data: item.value as! NSData) {
                        extractedImage = image
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                    }
                }
            }
        }
        
        return nowPlayingInfo
    }
    
    // MARK: NSCoding
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: PropertyKey.nameKey)
        aCoder.encodeObject(artist, forKey: PropertyKey.artistKey)
        aCoder.encodeInteger(id, forKey: PropertyKey.IdKey)
        aCoder.encodeInteger(album, forKey: PropertyKey.albumKey)
        aCoder.encodeInteger(plays, forKey: PropertyKey.playsKey)
        aCoder.encodeObject(lastPlayed, forKey: PropertyKey.lastPlayedKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObjectForKey(PropertyKey.nameKey) as! String
        let artist = aDecoder.decodeObjectForKey(PropertyKey.artistKey) as! String
        let id = aDecoder.decodeIntegerForKey(PropertyKey.IdKey)
        let album = aDecoder.decodeIntegerForKey(PropertyKey.albumKey)
        let plays = aDecoder.decodeIntegerForKey(PropertyKey.playsKey)
        let lastPlayed = aDecoder.decodeObjectForKey(PropertyKey.lastPlayedKey) as? NSDate
        
        self.init(name: name, artist: artist, id: id, album: album, plays: plays, lastPlayed: lastPlayed)
    }
    
    // MARK: Image
    
    func getImageUrl() -> NSURL {
        return SongLibrary.DocumentsDirectory.URLByAppendingPathComponent("\(album).jpg")
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
            } else {
                self.load()
            }
        })
        
        query.resume()
    }
    
    // MARK: Media
    
    func getMediaUrl() -> NSURL {
        return SongLibrary.DocumentsDirectory.URLByAppendingPathComponent("\(id).mp3")
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
            } else {
                self.loadMedia()
            }
        })
        
        query.resume()
    }
    
    // MARK: Notification
    
    func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(Song.notificationKey, object: self)
    }
}