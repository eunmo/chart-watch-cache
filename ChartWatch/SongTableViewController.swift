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
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: [])
        _ = try? AVAudioSession.sharedInstance().setActive(true, withOptions: [])
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification", name: Song.notificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification", name: SongLibrary.notificationKey, object: nil)
        
        if let tabBarController = self.tabBarController as? CustomTabBarController {
            songLibrary = tabBarController.songLibrary
        }
    }
    
    func receiveNotification() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songLibrary?.songs.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell

        // Fetch song
        let song = songLibrary!.getSongAtIndex(indexPath)!
        
        // Configure the cell...
        cell.nameLabel.text = song.name
        cell.artistLabel.text = song.artist
        if song.loaded {
            cell.albumImageView.image = song.photo
            cell.activityIndicator.stopAnimating()
        } else {
            cell.albumImageView.image = nil
            cell.activityIndicator.startAnimating()
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let song = songLibrary!.selectSongAtIndex(indexPath) {
            playSong(song)
        }
    }
    
    func playSong(song: Song) {
        let url = song.getMediaUrl()
        do {
            if playing {
                player.stop()
            }
            
            player = try AVAudioPlayer(contentsOfURL: url)
            player.delegate = self
            player.prepareToPlay()
            
            var nowPlayingInfo = song.getNowPlayingInfo()
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
            
            playerViewTitleLabel.text = song.name
            playerViewArtistLabel.text = song.artist
            playerImageView.image = song.extractedImage
            
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: Actions
    
    @IBAction func reload(sender: UIBarButtonItem) {
        songLibrary?.fetch()
    }
    
    @IBAction func tapPlayerImage(sender: UITapGestureRecognizer) {
        toggle()
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
        print ("play")
        if loaded {
            player.play()
            playing = true
        }
    }
    
    func toggle() {
        print ("toggle")
        if playing {
            pause()
        } else {
            play()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if flag, let song = songLibrary?.selectNextSong() {
            playSong(song)
        }
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        switch event!.subtype {
        case .RemoteControlTogglePlayPause:
            toggle()
        case .RemoteControlPlay:
            play()
        case .RemoteControlPause:
            pause()
        default:break
        }
        
    }
}
