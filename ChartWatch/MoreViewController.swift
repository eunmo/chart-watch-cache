//
//  MoreViewController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/25/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit

class MoreViewController: UIViewController {

    // MARK: Properties
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pushButton: UIButton!
    @IBOutlet weak var pullButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var syncButton: UIButton!
    
    var inNetworkWait = false
    
    var songLibrary: SongLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(MoreViewController.receiveNotification), name: NSNotification.Name(rawValue: SongLibrary.notificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MoreViewController.receiveNetworkNotification), name: NSNotification.Name(rawValue: SongLibrary.networkNotificationKey), object: nil)
        
        if let tabBarController = self.tabBarController as? CustomTabBarController {
            songLibrary = tabBarController.songLibrary
        }
        
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUI() {
        if let count = songLibrary?.getCount() {
            subtitleLabel.text = "\(count) songs cached"
        } else {
            subtitleLabel.text = "No song cached"
        }
        
        let canPush = songLibrary?.canPush()
        
        if inNetworkWait {
            activityIndicator.startAnimating()
            
            pushButton.isEnabled = false
            pullButton.isEnabled = false
            updateButton.isEnabled = false
            syncButton.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            
            pushButton.isEnabled = canPush ?? false
            pullButton.isEnabled = true
            updateButton.isEnabled = !(canPush ?? true)
            syncButton.isEnabled = true
        }
        
        print ("Update UI")
    }
    
    func receiveNotification() {
        DispatchQueue.main.async(execute: {
            self.updateUI()
        })
    }
    
    func receiveNetworkNotification() {
        inNetworkWait = false
        receiveNotification()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: Action
    
    @IBAction func cleanup(_ sender: UIButton) {
        if let message = songLibrary?.cleanup() {
            let alertController = UIAlertController(title: "Cleanup", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func startNetworkReuqest() {
        inNetworkWait = true
        receiveNotification()
    }
    
    @IBAction func push(_ sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.push()
    }
    
    @IBAction func pull(_ sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.pull()
    }
    
    @IBAction func update(_ sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.fetch()
    }
    
    @IBAction func sync(_ sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.sync()
    }
}
