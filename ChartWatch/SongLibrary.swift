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
    var shuffleId = 0
    var shuffle = false
    var stop = false
    var bedtime = 0
    
    var songIds = [Int:Song]()
    var albumIds = Set<Int>()
    let dateFormatter: NSDateFormatter = NSDateFormatter()
    let songSections = ["current", "seasonal", "charted", "uncharted"]
    var sectionLimits = [100, 3, 300, 100]
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("songs")
    static let LimitsURL = DocumentsDirectory.URLByAppendingPathComponent("limits")
    
    // MARK: Notification Key
    
    static let notificationKey = "songLibraryNotificationKey"
    static let networkNotificationKey = "songLibraryNetworkNotificationKey"
    static let serverAddress = "http://39.118.139.72:3000"
    
    // MARK: Constructor
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        initSections()
        
        loadLimits()
        load()
    }
    
    func initSections() {
        sections = [[Song]]()
        for _ in songSections {
            sections.append([Song]())
        }
    }
    
    func initMaps() {
        songIds = [Int:Song]()
        albumIds = Set<Int>()
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
    
    func selectRandomSong() -> Song? {
        bedtime = 0
        stop = false
        selected = false
        
        return getRandomSong()
    }
    
    func getRandomSong() -> Song? {
        if songIds.count > 0 {
            selected = false
            shuffle = true
            let randomIndex = Int(arc4random_uniform(UInt32(songIds.count)))
            let song = Array(songIds.values)[randomIndex]
            print("random \(randomIndex) \(song.name)")
            shuffleId = song.id
            
            return song
        }
        
        return nil
    }
    
    func selectSongAtIndex(index: NSIndexPath) -> Song? {
        let section = index.section
        let row = index.row
        
        stop = false
        shuffle = false
        
        if row < sections[section].count {
            curSection = section
            curSongIndex = row
            selected = true
            return sections[section][row]
        } else {
            return nil
        }
    }
    
    func getSelectedSong() -> Song? {
        if selected {
            return sections[curSection][curSongIndex]
        } else if shuffle {
            return songIds[shuffleId]
        } else {
            return nil
        }
    }
    
    func recordPlay() {
        if let song = getSelectedSong() {
            song.recordPlay()
            save()
        }
    }
    
    func selectNextSong() -> Song? {
        if stop {
            return nil
        } else if shuffle {
            if bedtime > 0 {
                bedtime--
                if bedtime == 0 {
                    stop = true
                }
            }
            return getRandomSong()
        } else if selected {
            if curSongIndex + 1 < sections[curSection].count {
                curSongIndex++
                return sections[curSection][curSongIndex]
            }
        }
        
        selected = false
        shuffle = false
        return nil
    }
    
    // MARK: Play Mode
    
    func changePlayMode() {
        if !shuffle { // serial -> shuffle
            shuffle = true
        } else if !stop {
            if bedtime == 0 { // shuffle -> bedtime
                bedtime = 4
            } else { // bedtime -> last song
                bedtime = 0
                stop = true
            }
        } else { // last song -> original
            if selected {
                shuffle = false
            }
            stop = false
        }
    }
    
    func getSongDisplayString() -> String {
        var string = ""
        let song = getSelectedSong()!
        
        for (index, section) in sections.enumerate() {
            for sectionSong in section {
                if song.id == sectionSong.id {
                    string += " / \(songSections[index].capitalizedString)"
                    break
                }
            }
        }
        
        assert(!string.isEmpty)
        
        string += " / \(song.plays) play" + (song.plays > 1 ? "s" : "")
        
        return string
    }
    
    func getPlayModeString() -> String {
        var string = ""
        
        if stop {
            string += "Last song"
        } else if bedtime > 0 {
            string += "Bedtime in \(bedtime)"
        }else if shuffle {
            string += "Shuffle"
        } else {
            string += "Serial"
        }
        
        string += getSongDisplayString()
        
        return string
    }
    
    func getSectionHeaderString(section: Int) -> String {
        return "\(sections[section].count) \(songSections[section]) songs"
    }
    
    // MARK: Limits
    
    func getLimit(sectionName: String) -> Int {
        if let section = songSections.indexOf(sectionName) {
            return sectionLimits[section]
        }
        
        return 0
    }
    
    func setLimit(sectionName: String, limit: Int) {
        if let section = songSections.indexOf(sectionName) where limit >= 0 {
            sectionLimits[section] = limit
            saveLimits()
        }
    }
    
    func getLimitParameterString() -> String {
        var params = "?"
        
        for section in songSections {
            let limit = getLimit(section)
            params += "\(section)=\(limit)&"
        }
        
        return params
    }
    
    // MARK: NSCoding
    
    func save() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sections, toFile: SongLibrary.ArchiveURL.path!)
        notify()
        print ("save")
        if !isSuccessfulSave {
            print("Failed to save songs...")
        }
    }
    
    func saveLimits() {
        NSKeyedArchiver.archiveRootObject(sectionLimits, toFile: SongLibrary.LimitsURL.path!)
    }
    
    func load() -> Bool {
        let savedSongs = NSKeyedUnarchiver.unarchiveObjectWithFile(SongLibrary.ArchiveURL.path!) as? [[Song]]
        
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
    
    func loadLimits() {
        if let savedLimits = NSKeyedUnarchiver.unarchiveObjectWithFile(SongLibrary.LimitsURL.path!) as? [Int]
        where savedLimits.count == sections.count {
            sectionLimits = savedLimits
        }
    }
    
    // MARK: Manage
    
    func registerSong(song: Song) {
        songIds[song.id] = song
        albumIds.insert(song.album)
    }
    
    func songFromJSON(songRow: JSON) -> Song {
        let songId = songRow["id"].intValue
        let albumId = songRow["albumId"].intValue
        let title = songRow["title"].stringValue.stringByReplacingOccurrencesOfString("`", withString: "'")
        let plays = songRow["plays"].intValue
        
        var artists = [String]()
        for (_, artistRow) in songRow["songArtists"] {
            let artist = artistRow["name"].stringValue.stringByReplacingOccurrencesOfString("`", withString: "'")
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
        return Song(name: title, artist: artistString, id: songId, album: albumId, plays: plays, lastPlayed: nil)!
    }
    
    func sectionFromJSON(section: String, json: JSON) {
        let jsonSection = json[section]
        let sectionIndex = songSections.indexOf(section)!
        
        for (_, songRow) in jsonSection {
            let song = songFromJSON(songRow)
            sections[sectionIndex] += [song]
            registerSong(song)
            song.load()
        }
    }
    
    func fetch() {
        initSections()
        
        let urlAsString = SongLibrary.serverAddress + "/api/ios/fetch" + getLimitParameterString()
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let jsonQuery = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            if error != nil {
                // should do something
            } else {
                self.songIds = [Int:Song]()
                self.albumIds = Set<Int>()
                
                let json = JSON(data: data!)
                
                for section in self.songSections {
                    print(section)
                    self.sectionFromJSON(section, json: json)
                }
                
                self.save()
                self.notifyNetworkDone()
                print (self.getCount())
            }
        })
        
        jsonQuery.resume()
    }
    
    func rebuildMaps() {
        songIds = [Int:Song]()
        albumIds = Set<Int>()
        
        for section in sections {
            for song in section {
                registerSong(song)
            }
        }
    }
    
    func cleanup() -> String? {
        var message: String?
        rebuildMaps()
        
        do {
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(SongLibrary.DocumentsDirectory, includingPropertiesForKeys: [], options: [])
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
                self.notifyNetworkDone()
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
                self.notifyNetworkDone()
                
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
    
    func notify() {
        NSNotificationCenter.defaultCenter().postNotificationName(SongLibrary.notificationKey, object: self)
    }
    
    func notifyNetworkDone() {
        NSNotificationCenter.defaultCenter().postNotificationName(SongLibrary.networkNotificationKey, object: self)
    }
}