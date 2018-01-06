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
        songLibrary!.loadSongs()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
