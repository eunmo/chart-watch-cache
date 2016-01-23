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
    var section = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.title = songLibrary!.getSectionName(section)
        self.tableView.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification", name: Song.notificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification", name: SongLibrary.notificationKey, object: nil)
    }
    
    func receiveNotification() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songLibrary!.getSectionSongCount(self.section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongSectionTableViewCell", forIndexPath: indexPath) as! SongSectionTableViewCell

        // Configure the cell...
        let adjustedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: section)
        let song = songLibrary!.getSongAtIndex(adjustedIndexPath)!
        
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return "\(songLibrary!.getSectionSongCount(self.section)) Songs"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let adjustedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: section)
        if let song = songLibrary!.selectSongAtIndex(adjustedIndexPath) {
            player?.playSong(song)
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
