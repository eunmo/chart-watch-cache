//
//  CustomTabBarController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 12/25/15.
//  Copyright © 2015 Eunmo Yang. All rights reserved.
//

import UIKit

class CustomTabBarController: UITabBarController {
    
    // MARK: Properties
    
    var songLibrary: SongLibrary?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        songLibrary = SongLibrary()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let alertController = UIAlertController(title: "Where are you?", message: "", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Outside", style: UIAlertActionStyle.default, handler: outsideHandler))
        alertController.addAction(UIAlertAction(title: "Home", style: UIAlertActionStyle.default, handler: homeHandler))
        alertController.preferredAction = alertController.actions[1] // Home
        present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setLocation(home: Bool) {
        songLibrary!.setLocation(home: home)
        songLibrary!.loadSongs()
    }
    
    func outsideHandler(action: UIAlertAction!) -> Void {
        setLocation(home: false)
    }
    
    func homeHandler(action: UIAlertAction!) -> Void {
        setLocation(home: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
