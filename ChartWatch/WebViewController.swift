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
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: WebViewController.notificationKey), object: self, userInfo: userInfo)
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
