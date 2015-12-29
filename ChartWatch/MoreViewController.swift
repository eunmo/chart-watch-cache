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
    @IBOutlet weak var chartedLimitLabel: UILabel!
    @IBOutlet weak var chartedLimitStepper: UIStepper!
    
    var inNetworkWait = false
    
    var songLibrary: SongLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification", name: SongLibrary.notificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNetworkNotification", name: SongLibrary.networkNotificationKey, object: nil)
        
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
            
            pushButton.enabled = false
            pullButton.enabled = false
            updateButton.enabled = false
        } else {
            activityIndicator.stopAnimating()
            
            pushButton.enabled = canPush ?? false
            pullButton.enabled = true
            updateButton.enabled = !(canPush ?? true)
        }
        
        let chartedLimit = songLibrary?.getLimit("charted") ?? 0
        chartedLimitStepper.value = Double(chartedLimit)
        chartedLimitLabel.text = "\(Int(chartedLimitStepper.value)) charted songs"
        
        print ("Update UI")
    }
    
    func receiveNotification() {
        dispatch_async(dispatch_get_main_queue(), {
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
    
    @IBAction func cleanup(sender: UIButton) {
        if let message = songLibrary?.cleanup() {
            let alertController = UIAlertController(title: "Cleanup", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func startNetworkReuqest() {
        inNetworkWait = true
        receiveNotification()
    }
    
    @IBAction func push(sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.push()
    }
    
    @IBAction func pull(sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.pull()
    }
    
    @IBAction func update(sender: UIButton) {
        startNetworkReuqest()
        songLibrary?.fetch()
    }
    
    @IBAction func chartedLimitChanged(sender: UIStepper) {
        let limit = Int(sender.value)
        chartedLimitLabel.text = "\(limit) charted songs"
        songLibrary?.setLimit("charted", limit: limit)
    }
}
