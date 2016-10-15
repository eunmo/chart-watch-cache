//
//  NetShuffleTableViewController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 10/14/16.
//  Copyright © 2016 Eunmo Yang. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class NetShuffleTableViewController: UITableViewController, AVAudioPlayerDelegate {
    
    var songs = [NetworkSong]()
    var player = AVAudioPlayer()
    var playing = false
    
    // MARK: Notification Key
    
    static let notificationKey = "netShuffleNotificationKey"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        _ = try? AVAudioSession.sharedInstance().setActive(true, with: [])
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(NetShuffleTableViewController.receiveNotification), name: NSNotification.Name(rawValue: NetShuffleTableViewController.notificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetShuffleTableViewController.receiveSongLoadedNotification), name: NSNotification.Name(rawValue: NetworkSong.notificationKey), object: nil)
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.update()
        })
    }
    
    func receiveSongLoadedNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.playFirst()
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NetShuffleTableViewCell", for: indexPath)

        // Configure the cell...
        let row = indexPath.row
        let song = songs[row]
        
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist

        return cell
    }
    
    func playFirst() {
        if songs.count == 0 {
            return
        }
        
        if songs.count > 1 && songs[1].loaded {
            print("next song loaded")
            return // preload
        }
        
        print("PLAY FIRST")
        
        let song = songs[0]
        
        if (song.loaded == false) {
            song.load()
            return
        }
        
        let url = song.getMediaUrl()
        
        do {
            if playing {
                player.stop()
            }
            
            player = try AVAudioPlayer(contentsOf: url as URL)
            player.delegate = self
            player.prepareToPlay()
            
            var nowPlayingInfo = song.getNowPlayingInfo()
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration as AnyObject?
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime as AnyObject?
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            if (songs.count > 1) {
                songs[1].load()
            }
            
            play()
        } catch {
            
        }
    }
    
    // MARK: Player
    
    func pause() {
        print ("pause")
        if playing {
            player.pause()
            playing = false
        }
    }
    
    func play() {
        player.play()
        playing = true
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyPlaybackDuration] = player.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
    }
    
    func toggle() {
        print ("toggle")
        if playing {
            pause()
        } else {
            play()
        }
    }
    
    func playerDidFinishPlaying() {
        let song = songs[0]
        // record play
        print("\(song.id) done")
        
        songs.remove(at: 0)
        update()
        playFirst()
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            let song = songs[0]
            // record play
            print("\(song.id) done")
            song.recordPlay()
            
            songs.remove(at: 0)
            update()
            playFirst()
        }
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        switch event!.subtype {
        case .remoteControlTogglePlayPause:
            toggle()
        case .remoteControlPlay:
            play()
        case .remoteControlPause:
            pause()
        default:break
        }
        
    }
    
    // MARK: Actions
    
    @IBAction func refresh(_ sender: UIBarButtonItem) {
        songs.removeAll()
        
        let urlAsString = SongLibrary.serverAddress + "/shuffle"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let jsonQuery = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if error != nil {
                // should do something
            } else {
                print("YEA")
                let json = JSON(data: data!)
                
                for (_, song) in json {
                    self.songs.append(NetworkSong(json: song))
                }
            }
            
            let song = self.songs[0]
            song.load()
            print(song.id)
            
            self.notifyNetworkDone()
        })
        
        jsonQuery.resume()
    }
    
    func notifyNetworkDone() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetShuffleTableViewController.notificationKey), object: self)
    }
}
