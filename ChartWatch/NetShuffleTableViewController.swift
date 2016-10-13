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

class NetShuffleTableViewController: UITableViewController {
    
    var songs = [JSON]()
    var player = AVPlayer()
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
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.update()
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
        let title = song["title"].stringValue.replacingOccurrences(of: "`", with: "'")
        
        var artistString = ""
        var i = 0
        for (_, artistRow) in song["artists"] {
            if i > 0 {
                artistString += ", "
            }
            artistString += artistRow["name"].stringValue.replacingOccurrences(of: "`", with: "'")
            i += 1
        }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = artistString

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
     */
    
    func playFirst() {
        if songs.count == 0 {
            return
        }
        
        print("PLAY FIRST")
        
        let song = songs[0]
        let urlAsString = SongLibrary.serverAddress + "/music/\(song["id"]).mp3"
        let url = URL(string: urlAsString)!
        
        let title = song["title"].stringValue.replacingOccurrences(of: "`", with: "'")
        
        var artistString = ""
        var i = 0
        for (_, artistRow) in song["artists"] {
            if i > 0 {
                artistString += ", "
            }
            artistString += artistRow["name"].stringValue.replacingOccurrences(of: "`", with: "'")
            i += 1
        }
        
        do {
            //player = try AVAudioPlayer(contentsOf: url)
            //player.delegate = self
            //player.prepareToPlay()
            
            player = try AVPlayer(url: url)
            NotificationCenter.default.addObserver(self, selector: #selector(NetShuffleTableViewController.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            
            
            var nowPlayingInfo:[String: AnyObject] = [
                MPMediaItemPropertyTitle: title as AnyObject,
                MPMediaItemPropertyArtist: artistString as AnyObject,
            ]
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            //MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyTitle] = title
            //MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyArtist] = artistString
        
            play()
        } catch {
            print ("error: \(error)")
            // ???
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
        print ("play \(CMTimeGetSeconds((player.currentItem?.duration)!))")
        player.play()
        playing = true
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds((player.currentItem?.duration)!)
        //MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
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
        print("\(song["id"]) done")
        
        songs.remove(at: 0)
        update()
        playFirst()
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            let song = songs[0]
            // record play
            print("\(song["id"]) done")
            
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
                    self.songs.append(song)
                }
            }
            
            let song = self.songs[0]
            print(song)
            print(song["id"])
            
            self.notifyNetworkDone()
        })
        
        jsonQuery.resume()
    }
    
    func notifyNetworkDone() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetShuffleTableViewController.notificationKey), object: self)
    }
}
