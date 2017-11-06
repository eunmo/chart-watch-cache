//
//  SongSectionTableViewController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 1/23/16.
//  Copyright © 2016 Eunmo Yang. All rights reserved.
//

import UIKit

class SongSectionTableViewController: UITableViewController {
    
    // MARK: Properties
    var player: SongTableViewController?
    var songLibrary: SongLibrary?
    var songs: [Song]?
    var section = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.title = songLibrary!.getSectionName(section)
        update()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SongSectionTableViewController.receiveNotification), name: NSNotification.Name(rawValue: Song.notificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SongSectionTableViewController.receiveNotification), name: NSNotification.Name(rawValue: SongLibrary.notificationKey), object: nil)
    }
    
    func update() {
        songs = songLibrary!.getSectionSongs(section)
        tableView.reloadData()
    }
    
    @objc func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.update()
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongSectionTableViewCell", for: indexPath) as! SongSectionTableViewCell

        // Configure the cell...
        let song = songs![(indexPath as NSIndexPath).row]
        
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
        cell.playCountLabel.text = "\(song.plays)"
        let red = CGFloat(100 - song.plays) / 100.0
        cell.playCountLabel.backgroundColor = UIColor(red: 1.0 - red, green: 0.5, blue: red, alpha: 0.3)
        cell.playCountLabel.layer.cornerRadius = 8.0
        cell.playCountLabel.layer.masksToBounds = true

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return "\(songs!.count) Songs"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let song = songLibrary!.selectSongAtIndex(section, index: (indexPath as NSIndexPath).row) {
            let alertController = UIAlertController(title: "Play song?", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                self.player?.playSong(song)
                self.navigationController!.popViewController(animated: true)
            }))
            alertController.preferredAction = alertController.actions[1] // Done
            present(alertController, animated: true, completion: nil)
        }
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

}
