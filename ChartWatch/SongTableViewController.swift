//
//  SongTableViewController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/21/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class SongTableViewController: UITableViewController, AVAudioPlayerDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playerViewTitleLabel: UILabel!
    @IBOutlet weak var playerViewArtistLabel: UILabel!
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var playModeLabel: UILabel!
    
    var songLibrary: SongLibrary?
    var player = AVAudioPlayer()
    var playing = false
    var loaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        _ = try? AVAudioSession.sharedInstance().setActive(true, with: [])
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SongTableViewController.receiveNotification), name: NSNotification.Name(rawValue: Song.notificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SongTableViewController.receiveNotification), name: NSNotification.Name(rawValue: SongLibrary.notificationKey), object: nil)
        
        if let tabBarController = self.tabBarController as? CustomTabBarController {
            songLibrary = tabBarController.songLibrary
        }
        
        initUI()
    }
    
    func initUI() {
        playerViewTitleLabel.text = "ChartWatch"
        playerViewArtistLabel.text = ""
        playerImageView.image = nil
        playModeLabel.text = ""
    }
    
    @objc func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songLibrary!.getSectionCount() + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = songLibrary!.getSectionName((indexPath as NSIndexPath).row)
        
        let songCount = songLibrary!.getSectionSongCount((indexPath as NSIndexPath).row)
        let loadedCount = songLibrary!.getSectionLoadedSongCount((indexPath as NSIndexPath).row)
        if songCount == loadedCount {
            cell.detailTextLabel?.text = "\(songCount) Songs"
        } else {
            cell.detailTextLabel?.text = "\(loadedCount)/\(songCount) Songs"
        }

        return cell
    }
    
    func playSong(_ song: Song) {
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
            
            let displayString = songLibrary!.getSongDisplayString()
            let index = displayString.index(displayString.startIndex, offsetBy: 3)
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = displayString.substring(from: index) as AnyObject?
                
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            playerViewTitleLabel.text = song.name
            playerViewArtistLabel.text = song.artist
            playerImageView.image = song.largePhoto
            
            loaded = true
            
            play()
        } catch {
            
        }
        
        print ("\(song.name) selected")
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "Show Section":
                if let vc = segue.destination as? SongSectionTableViewController {
                    vc.player = self
                    vc.songLibrary = songLibrary
                    vc.section = (tableView.indexPathForSelectedRow! as NSIndexPath).row
                }
                
            default: break
            }
        }
    }

    // MARK: Actions
    
    @IBAction func reload(_ sender: UIBarButtonItem) {
        let song = songLibrary?.selectRandomSong()
        if song != nil {
            playSong(song!)
        }
    }
    
    @IBAction func tapPlayerImage(_ sender: UITapGestureRecognizer) {
        toggle()
    }
    
    @IBAction func tapPlayModeLabel(_ sender: UITapGestureRecognizer) {
        if playModeLabel.text != "+++" {
            songLibrary?.changePlayMode()
        }
        print("play mode selected")
        playModeLabel.text = songLibrary?.getPlayModeString()
    }
    
    // MARK: Player
    
    func pause() {
        NSLog("S pause")
        if playing {
            player.pause()
            playing = false
        }
    }
    
    func play() {
        NSLog("S play")
        if loaded {
            player.play()
            playing = true

            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyPlaybackDuration] = player.duration
            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            
            playModeLabel.text = "+++"
        }
    }
    
    func toggle() {
        NSLog("S toggle")
        if playing {
            pause()
        } else {
            play()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NSLog("S audioPlayerDidFinishPlaying")
        if flag {
            songLibrary?.recordPlay()
            if let song = songLibrary?.selectNextSong() {
                playSong(song)
            } else {
                initUI()
            }
        }
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        NSLog("S remoteControlReceived")
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
}
