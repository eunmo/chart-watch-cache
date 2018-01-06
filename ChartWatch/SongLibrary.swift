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
    let dateFormatter: DateFormatter = DateFormatter()
    let songSections = ["current", "album", "seasonal", "charted", "uncharted", "favorite"]
    
    var serverAddress = ""
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("songs")
    static let LimitsURL = DocumentsDirectory.appendingPathComponent("limits")
    
    // MARK: Notification Key
    
    static let notificationKey = "songLibraryNotificationKey"
    static let networkNotificationKey = "songLibraryNetworkNotificationKey"
    
    // MARK: Constructor
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        initSections()
        
        //loadLimits()
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
    
    // MARK: Location
    
    func setLocation(home: Bool) {
        serverAddress = home ? "http://192.168.219.137:3000" : "http://124.49.11.117:3000"
    }
    
    // MARK: Getters
    
    func getSectionCount() -> Int {
        return sections.count
    }
    
    func getSectionSongCount(_ section: Int) -> Int {
        if section < 0 || section > getSectionCount() {
            return 0
        } else if section == getSectionCount() {
            return getLocallyPlayedSongs().count
        } else {
            return sections[section].count
        }
    }
    
    func getSectionLoadedSongCount(_ section: Int) -> Int {
        if section < 0 || section > getSectionCount() {
            return 0
        } else if section == getSectionCount() {
            return getLocallyPlayedSongs().count
        } else {
            var count = 0
            
            for song in sections[section] {
                if song.loaded {
                    count += 1
                }
            }
            
            return count
        }
    }
    
    func getCount() -> Int {
        return songIds.count
    }
    
    func getSongAtIndex(_ section: Int, index: Int) -> Song? {
        if section < sections.count && index < sections[section].count {
            return sections[section][index]
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
    
    func selectSongAtIndex(_ section: Int, index: Int) -> Song? {
        
        stop = false
        shuffle = false
        
        if let song = getSongAtIndex(section, index: index) {
            curSection = section
            curSongIndex = index
            selected = true
            return song
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
                bedtime -= 1
                if bedtime == 0 {
                    stop = true
                }
            }
            return getRandomSong()
        } else if selected {
            if curSongIndex + 1 < sections[curSection].count {
                curSongIndex += 1
                return sections[curSection][curSongIndex]
            }
        }
        
        selected = false
        shuffle = false
        return nil
    }
    
    // MARK: Locally Played
    
    func getLocallyPlayedSongs() -> [Song] {
        var locallyPlayedSongs = [Song]()
        
        for (_, song) in songIds {
            if song.lastPlayed != nil {
               locallyPlayedSongs.append(song)
            }
        }
        
        locallyPlayedSongs.sort(by: { $0.lastPlayed!.compare($1.lastPlayed! as Date) == ComparisonResult.orderedAscending })
        
        return locallyPlayedSongs
    }
    
    func getSectionSongs(_ section: Int) -> [Song] {
        if section < 0 || section > getSectionCount() {
            return [Song]()
        } else if section == getSectionCount() {
            return getLocallyPlayedSongs()
        } else {
            return sections[section]
        }
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
        
        for (index, section) in sections.enumerated() {
            for sectionSong in section {
                if song.id == sectionSong.id {
                    string += " / \(songSections[index].capitalized)"
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
    
    func getSectionName(_ section: Int) -> String {
        if section == sections.count {
            return "Locally Played Songs"
        } else {
            return "\(songSections[section].capitalized) Songs"
        }
    }
    
    // MARK: NSCoding
    
    func save() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(sections, toFile: SongLibrary.ArchiveURL.path)
        notify()
        print ("save")
        if !isSuccessfulSave {
            print("Failed to save songs...")
        }
    }
    
    func load() {
        let savedSongs = NSKeyedUnarchiver.unarchiveObject(withFile: SongLibrary.ArchiveURL.path) as? [[Song]]
        
        if savedSongs != nil {
            sections = savedSongs!
            for section in sections {
                for song in section {
                    _ = registerSong(song)
                }
            }
        }
    }
    
    // MARK: Manage
    
    func registerSong(_ song: Song) -> Song {
        if let oldSong = songIds[song.id] {
            return oldSong
        } else {
            songIds[song.id] = song
            albumIds.insert(song.album)
            //song.load()
            return song
        }
    }
    
    func loadSongs() {
        for section in sections {
            for song in section {
                song.load(serverAddress: serverAddress)
            }
        }
        notify()
    }
    
    func songFromJSON(_ songRow: JSON) -> Song {
        let songId = songRow["id"].intValue
        let albumId = songRow["albumId"].intValue
        let title = songRow["title"].stringValue.replacingOccurrences(of: "`", with: "'")
        let plays = songRow["plays"].intValue
        
        var artistString = ""
        var i = 0
        for (_, artistRow) in songRow["artists"] {
            if i > 0 {
                artistString += ", "
            }
            artistString += artistRow["name"].stringValue.replacingOccurrences(of: "`", with: "'")
            i += 1
        }
    
        i = 0
        for (_, artistRow) in songRow["features"] {
            if i == 0 {
                artistString += " feat "
            } else {
                artistString += ", "
            }
            artistString += artistRow["name"].stringValue.replacingOccurrences(of: "`", with: "'")
            i += 1
        }
        
        return Song(name: title, artist: artistString, id: songId, album: albumId, plays: plays, lastPlayed: nil)!
    }
    
    func sectionFromJSON(_ section: String, json: JSON) {
        let jsonSection = json[section]
        let sectionIndex = songSections.index(of: section)!
        
        for (_, songRow) in jsonSection {
            let jsonSong = songFromJSON(songRow)
            let song = registerSong(jsonSong)
            sections[sectionIndex] += [song]
        }
    }
    
    func fetch() {
        initSections()
        
        let urlAsString = serverAddress + "/ios/fetch"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let jsonQuery = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if error != nil {
                // should do something
            } else {
                self.songIds = [Int:Song]()
                self.albumIds = Set<Int>()
                
                let json = JSON(data: data!)
                
                self.initSections()
                for section in self.songSections {
                    print(section)
                    self.sectionFromJSON(section, json: json)
                }
                
                self.loadSongs()
                self.cleanup()
                self.save()
                self.notifyNetworkDone()
            }
        })
        
        jsonQuery.resume()
    }
    
    func rebuildMaps() {
        songIds = [Int:Song]()
        albumIds = Set<Int>()
        
        for section in sections {
            for song in section {
                _ = registerSong(song)
            }
        }
    }
    
    func cleanup() -> String? {
        var message: String?
        rebuildMaps()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: SongLibrary.DocumentsDirectory, includingPropertiesForKeys: [], options: [])
            var mediaCount = 0
            var imageCount = 0
            var largeImageCount = 0
            var mediaDeleteCount = 0
            var imageDeleteCount = 0
            var largeImageDeleteCount = 0
            
            for file in files {
                switch file.pathExtension {
                case "mp3":
                    if let song = Int((file.deletingPathExtension().lastPathComponent)) , songIds[song] == nil {
                        try FileManager.default.removeItem(at: file)
                        mediaDeleteCount += 1
                    }
                    mediaCount += 1
                case "jpg":
                    if let album = Int((file.deletingPathExtension().lastPathComponent)) , !albumIds.contains(album) {
                        try FileManager.default.removeItem(at: file)
                        imageDeleteCount += 1
                    }
                    imageCount += 1
                case "jpeg":
                    if let album = Int((file.deletingPathExtension().lastPathComponent)) , !albumIds.contains(album) {
                        try FileManager.default.removeItem(at: file)
                        largeImageDeleteCount += 1
                    }
                    largeImageCount += 1
                default: break
                }
            }
            
            message = "\(mediaDeleteCount)/\(mediaCount) media files\n\(imageDeleteCount)/\(imageCount) image files\n\(largeImageDeleteCount)/\(largeImageCount) large image files"
            
            
        } catch {
            
        }
        
        return message
    }
    
    func push() {
        let urlAsString = serverAddress + "/ios/plays/push"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = getPushJSON().data(using: String.Encoding.utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if error != nil {
                print ("\(String(describing: error))")
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
                json += "{\"id\":\(song.id), \"plays\":\(song.plays), \"lastPlayed\":\"\(dateFormatter.string(from: song.lastPlayed! as Date))\"}"
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
        let urlAsString = serverAddress + "/ios/plays/pull"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = getPullJSON().data(using: String.Encoding.utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if error != nil {
                print ("\(String(describing: error))")
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
    
    func sync() {
        let urlAsString = serverAddress + "/ios/plays/push"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = getPushJSON().data(using: String.Encoding.utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if error != nil {
                print ("\(String(describing: error))")
            } else {
                self.fetch()
                print ("put successful")
            }
        })
        task.resume()
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SongLibrary.notificationKey), object: self)
    }
    
    func notifyNetworkDone() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SongLibrary.networkNotificationKey), object: self)
    }
}
