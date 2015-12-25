//
//  SongLibrary.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/25/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import Foundation

class SongLibrary {
    
    // MARK: Properties
    
    var songs = [Song]()
    var curSection = 0
    var curSongIndex = 0
    var selected = false
    
    // MARK: Notification Key
    
    static let notificationKey = "songLibraryNotificationKey"
    
    // MARK: Getters
    
    func getSongAtIndex(index: NSIndexPath) -> Song? {
        let row = index.row
        
        if row < songs.count {
            return songs[row]
        } else {
            return nil
        }
    }
    
    func selectSongAtIndex(index: NSIndexPath) -> Song? {
        let row = index.row
        
        if row < songs.count {
            curSongIndex = row
            selected = true
            return songs[row]
        } else {
            return nil
        }
    }
    
    func selectNextSong() -> Song? {
        if selected && curSongIndex + 1 < songs.count {
            curSongIndex++
            return songs[curSongIndex]
        } else {
            selected = false
            return nil
        }
    }
    
    // MARK: NSCoding
    
    func save() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(songs, toFile: Song.ArchiveURL.path!)
        if !isSuccessfulSave {
            print("Failed to save songs...")
        }
    }
    
    func load() -> Bool {
        let savedSongs = NSKeyedUnarchiver.unarchiveObjectWithFile(Song.ArchiveURL.path!) as? [Song]
        
        if savedSongs != nil {
            songs = savedSongs!
            for song in savedSongs! {
                song.load()
            }
        } else {
            fetch()
        }
        
        return savedSongs != nil
    }
    
    func fetch() {
        songs = [Song]()
        
        let urlAsString = "http://39.118.139.72:3000/chart/current"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let jsonQuery = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            let json = JSON(data: data!)
            
            for (_, songRow) in json {
                let songId = songRow["song"]["id"].intValue
                let albumId = songRow["song"]["Albums"][0]["id"].intValue
                let title = songRow["song"]["title"].stringValue
                let titleNorm = title.stringByReplacingOccurrencesOfString("`", withString: "'")
                
                var artists = [String]()
                for (_, artistRow) in songRow["songArtists"] {
                    let artist = artistRow["name"].stringValue
                    let order = artistRow["order"].intValue
                    artists.insert(artist, atIndex: order)
                }
                
                var artistString = ""
                for (i, artist) in artists.enumerate() {
                    if i > 0 {
                        artistString += ", "
                    }
                    artistString += artist
                }
                let song = Song(name: titleNorm, artist: artistString, id: songId, album: albumId)!
                song.load()
                
                self.songs += [song]
            }
            
            self.save()
            self.notify()
        })
        
        jsonQuery.resume()
    }
    
    @IBAction func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(SongLibrary.notificationKey, object: self)
    }
}