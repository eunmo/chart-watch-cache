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
    
    var sections = [[Song]]()
    var curSection = 0
    var curSongIndex = 0
    var selected = false
    
    var songIds = [Int:Song]()
    var albumIds = Set<Int>()
    let dateFormatter: NSDateFormatter = NSDateFormatter()
    var songSections = ["current":0, "charted":1]
    
    // MARK: Notification Key
    
    static let notificationKey = "songLibraryNotificationKey"
    static let serverAddress = "http://39.118.139.72:3000"
    
    // MARK: Constructor
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        initSections()
        
        load()
    }
    
    func initSections() {
        sections = [[Song]]()
        for (_, _) in songSections {
            sections.append([Song]())
        }
    }
    
    // MARK: Getters
    
    func getSectionCount() -> Int {
        return sections.count
    }
    
    func getSectionSongCount(section: Int) -> Int {
        if section < 0 || section >= getSectionCount() {
            return 0
        } else {
            return sections[section].count
        }
    }
    
    func getCount() -> Int {
        return songIds.count
    }
    
    func getSongAtIndex(index: NSIndexPath) -> Song? {
        let section = index.section
        let row = index.row
        
        if row < sections[section].count {
            return sections[section][row]
        } else {
            return nil
        }
    }
    
    func selectSongAtIndex(index: NSIndexPath) -> Song? {
        let section = index.section
        let row = index.row
        
        if row < sections[section].count {
            curSection = section
            curSongIndex = row
            selected = true
            return sections[section][row]
        } else {
            return nil
        }
    }
    
    func selectNextSong() -> Song? {
        if selected {
            let selectedSong = sections[curSection][curSongIndex]
            selectedSong.recordPlay()
            save()
            
            if curSongIndex + 1 < sections[curSection].count {
                curSongIndex++
                return sections[curSection][curSongIndex]
            }
        }
        
        selected = false
        return nil
    }
    
    // MARK: NSCoding
    
    func save() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sections, toFile: Song.ArchiveURL.path!)
        notify()
        print ("save")
        if !isSuccessfulSave {
            print("Failed to save songs...")
        }
    }
    
    func load() -> Bool {
        let savedSongs = NSKeyedUnarchiver.unarchiveObjectWithFile(Song.ArchiveURL.path!) as? [[Song]]
        
        if savedSongs != nil {
            sections = savedSongs!
            for section in sections {
                for song in section {
                    registerSong(song)
                    song.load()
                }
            }
        }
        
        return savedSongs != nil
    }
    
    // MARK: Manage
    
    func registerSong(song: Song) {
        songIds[song.id] = song
        albumIds.insert(song.album)
    }
    
    func songFromJSON(songRow: JSON) -> Song {
        let songId = songRow["id"].intValue
        let albumId = songRow["albumId"].intValue
        let title = songRow["title"].stringValue
        let titleNorm = title.stringByReplacingOccurrencesOfString("`", withString: "'")
        let plays = songRow["plays"].intValue
        
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
        return Song(name: titleNorm, artist: artistString, id: songId, album: albumId, plays: plays, lastPlayed: nil)!
    }
    
    func sectionFromJSON(section: String, json: JSON) {
        let jsonSection = json[section]
        let sectionIndex = songSections[section]!
        
        for (_, songRow) in jsonSection {
            let song = songFromJSON(songRow)
            sections[sectionIndex] += [song]
            registerSong(song)
            song.load()
        }
    }
    
    func fetch() {
        initSections()
        
        let urlAsString = SongLibrary.serverAddress + "/api/ios/fetch"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let jsonQuery = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            if error != nil {
                // should do something
            } else {
                let json = JSON(data: data!)
                
                for (section, _) in self.songSections {
                    print(section)
                    self.sectionFromJSON(section, json: json)
                }
                
                self.save()
                self.notify()
                print (self.getCount())
            }
        })
        
        jsonQuery.resume()
    }
    
    func cleanup() -> String? {
        var message: String?
        
        do {
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(Song.DocumentsDirectory, includingPropertiesForKeys: [], options: [])
            var mediaCount = 0
            var imageCount = 0
            var mediaDeleteCount = 0
            var imageDeleteCount = 0
            
            for file in files {
                switch file.pathExtension! {
                case "mp3":
                    if let song = Int((file.URLByDeletingPathExtension?.lastPathComponent)!) where songIds[song] == nil {
                        try NSFileManager.defaultManager().removeItemAtURL(file)
                        mediaDeleteCount++
                    }
                    mediaCount++
                case "jpg":
                    if let album = Int((file.URLByDeletingPathExtension?.lastPathComponent)!) where !albumIds.contains(album) {
                        try NSFileManager.defaultManager().removeItemAtURL(file)
                        imageDeleteCount++
                    }
                    imageCount++
                default: break
                }
            }
            
            message = "\(mediaDeleteCount)/\(mediaCount) media files\n\(imageDeleteCount)/\(imageCount) image files"
            
            
        } catch {
            
        }
        
        return message
    }
    
    func push() {
        let urlAsString = SongLibrary.serverAddress + "/api/ios/push"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.HTTPBody = getPushJSON().dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = urlSession.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
            if error != nil {
                print ("\(error)")
            } else {
                print ("put successful")
            }
        })
        task.resume()
    }
    
    func getPushJSON() -> String {
        var json = "["
        var added = false
        
        for (_, song) in songIds {
            if (song.lastPlayed != nil) {
                if added {
                    json += ","
                }
                json += "{\"id\":\(song.id), \"plays\":\(song.plays), \"lastPlayed\":\"\(dateFormatter.stringFromDate(song.lastPlayed!))\"}"
                added = true
            }
        }
        
        json += "]"
        print (json)
        return json
    }
    
    func canPush() -> Bool {
        
        for (_, song) in songIds {
            if song.lastPlayed != nil {
                return true
            }
        }
        
        return false
    }
    
    func pull() {
        let urlAsString = SongLibrary.serverAddress + "/api/ios/pull"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        request.HTTPBody = getPullJSON().dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = urlSession.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
            if error != nil {
                print ("\(error)")
            } else {
                let json = JSON(data: data!)
                
                for (_, songRow) in json {
                    let id = songRow["id"].intValue
                    let plays = songRow["plays"].intValue
                    let song = self.songIds[id]!
                    
                    if song.plays <= plays {
                        song.plays = plays
                        song.lastPlayed = nil
                    }
                    
                    print ("\(song.name) plays \(song.plays) -> \(plays)")
                }
                self.save()
                
                print ("put successful")
            }
        })
        task.resume()
        
    }
    
    func getPullJSON() -> String {
        var json = "["
        var added = false
        
        for (id, _) in songIds {
            if added {
                json += ","
            }
            json += "\(id)"
            added = true
        }
        
        json += "]"
        print (json)
        return json
    }
    
    @IBAction func notify() {
        print("notify")
        NSNotificationCenter.defaultCenter().postNotificationName(SongLibrary.notificationKey, object: self)
    }
}