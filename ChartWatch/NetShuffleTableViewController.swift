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
    
    var songLibrary: SongLibrary?
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(NetShuffleTableViewController.receiveNotification), name: NSNotification.Name(rawValue: NetShuffleTableViewController.notificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetShuffleTableViewController.receiveSongLoadedNotification), name: NSNotification.Name(rawValue: NetworkSong.notificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetShuffleTableViewController.receiveWebViewSongs), name: NSNotification.Name(rawValue: WebViewController.notificationKey), object: nil)
        
        if let tabBarController = self.tabBarController as? CustomTabBarController {
            songLibrary = tabBarController.songLibrary
        }
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func addSongsFromJSON(json: JSON) {
        for (_, song) in json {
            songs.append(NetworkSong(json: song))
        }
    
        let song = songs[0]
        song.load(serverAddress: songLibrary!.serverAddress)
    
        notifyNetworkDone()
    }
    
    @objc func receiveWebViewSongs(_ notification: NSNotification) {
        if let data = notification.userInfo?["json"] as? String {
            let json = JSON.parse(data)
            addSongsFromJSON(json: json)
        }
    }

    @objc func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.update()
        })
    }
    
    @objc func receiveSongLoadedNotification() {
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return "\(songs.count) Songs"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        songs.removeLast(songs.count - indexPath.row - 1) // keep the selected song
        update()
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
            song.load(serverAddress: songLibrary!.serverAddress)
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
                songs[1].load(serverAddress: songLibrary!.serverAddress)
            }
            
            play()
        } catch {
            
        }
    }
    
    // MARK: Player
    
    func pause() {
        NSLog("N pause")
        if playing {
            player.pause()
            playing = false
        }
    }
    
    func play() {
        NSLog("N play")
        player.play()
        playing = true
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyPlaybackDuration] = player.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
    }
    
    func toggle() {
        NSLog("N toggle")
        if playing {
            pause()
        } else {
            play()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NSLog("N audioPlayerDidFinishPlaying")
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
        NSLog("N remoteControlReceived")
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
    
    func notifyNetworkDone() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetShuffleTableViewController.notificationKey), object: self)
    }
}
