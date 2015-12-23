//
//  SongTableViewController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/21/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit

class SongTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var songs = [Song]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification", name: Song.notificationKey, object: nil)
        
        if let savedSongs = loadSongs() {
            songs = savedSongs
        } else {
            fetchSongs()
        }
    }
    
    func receiveNotification() {
        print("notified!")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    func fetchSongs() {
        songs = [Song]()
        
        let urlAsString = "http://39.118.139.72:3000/chart/current"
        let url = NSURL(string: urlAsString)!
        let urlSession = NSURLSession.sharedSession()
        
        let jsonQuery = urlSession.dataTaskWithURL(url, completionHandler: { data, response, error -> Void in
            let json = JSON(data: data!)
            
            for (_, songRow) in json {
                let songId = songRow["song"]["id"].intValue
                let albumId = songRow["song"]["Albums"][0]["id"].intValue
                let title = songRow["song"]["title"].stringValue
                let titleNorm = title.stringByReplacingOccurrencesOfString("`", withString: "'")
                
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
                let song = Song(name: titleNorm, artist: artistString, id: songId, album: albumId)!
                song.load()
                
                self.songs += [song]
            }
            
            self.saveSongs()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        })
        
        jsonQuery.resume()
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
        return songs.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell

        // Fetch song
        let song = songs[indexPath.row]
        
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
        fetchSongs()
    }
    
    // MARK: NSCoding
    
    func saveSongs() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(songs, toFile: Song.ArchiveURL.path!)
        if !isSuccessfulSave {
            print("Failed to save songs...")
        }
    }
    
    func loadSongs() -> [Song]? {
        let savedSongs = NSKeyedUnarchiver.unarchiveObjectWithFile(Song.ArchiveURL.path!) as? [Song]
        
        if savedSongs != nil {
            for song in savedSongs! {
                song.load()
            }
        }
        
        return savedSongs
    }
}
