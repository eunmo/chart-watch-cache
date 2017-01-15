//
//  WebViewController.swift
//  ChartWatch
//
//  Created by Eunmo Yang on 10/22/16.
//  Copyright © 2016 Eunmo Yang. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    // MARK: Properties
    
    @IBOutlet weak var webView: UIWebView!
    
    // MARK: Notification Key
    
    static let notificationKey = "webViewNotificationKey"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        webView.delegate = self
        
        let url = URL(string: SongLibrary.serverAddress)
        let request = URLRequest(url: url!)
        webView.loadRequest(request)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.stringByEvaluatingJavaScript(from: "setNative()")
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let s = request.url?.absoluteString {
            if s.hasPrefix("js:") {
                let data = s.components(separatedBy: "js://songs")[1].removingPercentEncoding!
                let userInfo:[String:String] = ["json": data]
                
                
                let json = JSON.parse(data)
                let title = "Stream \(json.count) song\(json.count > 1 ? "s" : "")?"
                
                let alertController = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
                alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
                    print (title)
                    self.tabBarController?.selectedIndex = 1
                    NotificationCenter.default.post(name: Notification.Name(rawValue: WebViewController.notificationKey), object: self, userInfo: userInfo)
                }))
                alertController.preferredAction = alertController.actions[1] // Done
                present(alertController, animated: true, completion: nil)
            }
        }
        
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
