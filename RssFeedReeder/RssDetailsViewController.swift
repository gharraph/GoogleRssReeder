//
//  RssDetailsViewController.swift
//  RssFeedReeder
//
//  Created by Sherief Gharraph on 5/14/16.
//  Copyright © 2016 Sherief. All rights reserved.
//

import UIKit

class RssDetailsViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func refreshButtonClicked(sender: AnyObject) {
        self.refreshWebView()
    }
    
    
    var link: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.delegate = self
        
        self.spinner.startAnimating()
        
        if let fetchURL = NSURL(string: self.link! ) {
            let urlRequest = NSURLRequest(URL: fetchURL)
            self.webView.loadRequest(urlRequest)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Webview delegate
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.spinner.stopAnimating()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        self.spinner.stopAnimating()
        self.showAlertMessage(alertTitle: "Error", alertMessage: "Error while loading url.")
    }
    
    private func showAlertMessage(alertTitle alertTitle: String, alertMessage: String ) -> Void {
        
        let alertCtrl = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert) as UIAlertController
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:
            { (action: UIAlertAction) -> Void in
        })
        
        alertCtrl.addAction(okAction)
        
        self.presentViewController(alertCtrl, animated: true, completion: { (void) -> Void in
        })
    }

    func refreshWebView(){
        self.spinner.startAnimating()
        self.webView.reload()
    }

}