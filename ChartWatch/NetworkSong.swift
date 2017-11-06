//
//  NetworkSong.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 10/15/16.
//  Copyright © 2016 Eunmo Yang. All rights reserved.
//

import UIKit
import MediaPlayer

class NetworkSong {
    
    // MARK: Properties
    
    var json: JSON
    var id: Int
    var name: String
    var artist: String
    var albumId: Int
    var plays: Int
    
    var photo: UIImage?
    var loaded: Bool
    
    // MARK: Notification Key
    
    static let notificationKey = "networkSongNotificationKey"
    
    init(json: JSON) {
        self.json = json
        self.id = json["id"].intValue
        self.name = json["title"].stringValue.replacingOccurrences(of: "`", with: "'")
        self.albumId = json["albumId"].intValue
        self.plays = json["plays"].intValue
        
        var artistString = ""
        var i = 0
        for (_, artistRow) in json["artists"] {
            if i > 0 {
                artistString += ", "
            }
            artistString += artistRow["name"].stringValue.replacingOccurrences(of: "`", with: "'")
            i += 1
        }
        self.artist = artistString
        
        self.photo = nil
        self.loaded = false
    }
    
    // MARK: Update
    
    func recordPlay() {
        let urlAsString = SongLibrary.serverAddress + "/api/play/song"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let putData = "{ \"id\":\(id) }"
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = putData.data(using: String.Encoding.utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if error != nil {
                print ("\(String(describing: error))")
            } else {
                print ("record play successful")
            }
        })
        task.resume()
    }
    
    // MARK: Information
    
    func getNowPlayingInfo() -> [String:AnyObject] {
        var nowPlayingInfo:[String: AnyObject] = [
            MPMediaItemPropertyTitle: name as AnyObject,
            MPMediaItemPropertyArtist: artist as AnyObject,
            ]
        
        if let image = photo {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        }
        
        let playString = "\(plays) play" + (plays > 1 ? "s" : "")
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = playString as AnyObject?
        
        return nowPlayingInfo
    }
    
    // MARK: Media
    
    func getMediaUrl() -> URL {
        return SongLibrary.DocumentsDirectory.appendingPathComponent("\(id + 1000000).mp3") // +1M to avoid clashing with cached songs
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
        
        let urlAsString = "\(SongLibrary.serverAddress)/music/\(id).mp3"
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
    
    // MARK: Image (no need to save to file)
    
    func loadImage() {
        
        let urlAsString = "\(SongLibrary.serverAddress)/\(albumId).jpg"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if data != nil {
                self.photo = UIImage(data: data!)
                self.loadMedia()
            } else {
                self.load()
            }
        })
        
        query.resume()
    }
    
    func load() {
        loadImage()
    }
    
    // MARK: Notification
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetworkSong.notificationKey), object: self)
    }
}
