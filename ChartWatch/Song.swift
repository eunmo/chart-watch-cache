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
    var lastPlayed: Date?
    
    var photo: UIImage?
    var largePhoto: UIImage?
    var loaded: Bool
    
    var serverAddress = ""
    
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
    
    init?(name: String, artist: String, id: Int, album: Int, plays: Int, lastPlayed: Date?) {
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
        plays += 1
        lastPlayed = Date()
        
        print ("\(name) played \(plays) times (last played \(String(describing: lastPlayed)))")
    }
    
    // MARK: Information
    
    func getNowPlayingInfo() -> [String:AnyObject] {
        var nowPlayingInfo:[String: AnyObject] = [
            MPMediaItemPropertyTitle: name as AnyObject,
            MPMediaItemPropertyArtist: artist as AnyObject,
        ]
        
        if let image = largePhoto {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        }
        
        return nowPlayingInfo
    }
    
    // MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(artist, forKey: PropertyKey.artistKey)
        aCoder.encode(id, forKey: PropertyKey.IdKey)
        aCoder.encode(album, forKey: PropertyKey.albumKey)
        aCoder.encode(plays, forKey: PropertyKey.playsKey)
        aCoder.encode(lastPlayed, forKey: PropertyKey.lastPlayedKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let artist = aDecoder.decodeObject(forKey: PropertyKey.artistKey) as! String
        let id = aDecoder.decodeInteger(forKey: PropertyKey.IdKey)
        let album = aDecoder.decodeInteger(forKey: PropertyKey.albumKey)
        let plays = aDecoder.decodeInteger(forKey: PropertyKey.playsKey)
        let lastPlayed = aDecoder.decodeObject(forKey: PropertyKey.lastPlayedKey) as? Date
        
        self.init(name: name, artist: artist, id: id, album: album, plays: plays, lastPlayed: lastPlayed)
    }
    
    func load(serverAddress: String) {
        self.serverAddress = serverAddress
        loadImage()
    }
    
    // MARK: Image
    
    func getImageUrl() -> URL {
        return SongLibrary.DocumentsDirectory.appendingPathComponent("\(album).jpg")
    }
    
    func saveImage(_ data: Data) {
        photo = UIImage(data: data)
        
        let fileUrl = getImageUrl()
        
        try? data.write(to: fileUrl, options: [.atomic])
        
        print("Saving image to \(fileUrl)")
    }
    
    func loadImage() {
        let filePath = getImageUrl().path
        if FileManager.default.fileExists(atPath: filePath) {
            photo = UIImage(contentsOfFile: filePath)
            if (photo != nil) {
                loadLargeImage()
                return
            }
        }
        
        let urlAsString = "\(serverAddress)/\(album).80px.jpg"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if data != nil {
                self.saveImage(data!)
                self.loadLargeImage()
            } else {
                self.loadImage()
            }
        })
        
        query.resume()
    }
    
    // MARK: Large Image
    
    func getLargeImageUrl() -> URL {
        return SongLibrary.DocumentsDirectory.appendingPathComponent("\(album).jpeg")
    }
    
    func saveLargeImage(_ data: Data) {
        largePhoto = UIImage(data: data)
        
        let fileUrl = getLargeImageUrl()
        
        try? data.write(to: fileUrl, options: [.atomic])
        
        print("Saving large image to \(fileUrl)")
    }
    
    func loadLargeImage() {
        
        let filePath = getLargeImageUrl().path
        if FileManager.default.fileExists(atPath: filePath) {
            largePhoto = UIImage(contentsOfFile: filePath)
            if (largePhoto != nil) {
                loadMedia()
                return
            }
        }
        
        let urlAsString = "\(serverAddress)/\(album).jpg"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if data != nil {
                self.saveLargeImage(data!)
                self.loadMedia()
            } else {
                self.loadLargeImage()
            }
        })
        
        query.resume()
    }
    
    // MARK: Media
    
    func getMediaUrl() -> URL {
        return SongLibrary.DocumentsDirectory.appendingPathComponent("\(id).mp3")
    }
    
    func saveMedia(_ data: Data) {
        
        let fileUrl = getMediaUrl()
        
        try? data.write(to: fileUrl, options: [.atomic])
        
        print("Saving media to \(fileUrl)")
    }
    
    func loadMedia() {
        
        let filePath = getMediaUrl().path
        if FileManager.default.fileExists(atPath: filePath) {
            loaded = true
            notify()
            return
        }
        
        let urlAsString = "\(serverAddress)/music/\(id).mp3"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
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
        NotificationCenter.default.post(name: Notification.Name(rawValue: Song.notificationKey), object: self)
    }
}
