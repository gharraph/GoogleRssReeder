//
//  ViewController.swift
//  RssFeedReeder
//
//  Created by Sherief Gharraph on 5/11/16.
//  Copyright © 2016 Sherief. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import XMLParser

class RssTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
        
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let imageCache = AutoPurgingImageCache(
        memoryCapacity: 100 * 1024 * 1024,
        preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
    )

    
    var rssRecordList : [RssRecord] = [RssRecord]()
    var selectedIndexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        spinner.hidesWhenStopped = true
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.rssRecordList.isEmpty {
            self.loadRSSData()
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     // MARK: - Table view dataSource and Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rssRecordList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("rssCell", forIndexPath: indexPath)
        
        let thisRecord : RssRecord  = self.rssRecordList[indexPath.row]
        
        if let cachedImage = getCachedImage(thisRecord.imageUrl){
            cell.imageView?.image =  cachedImage
        } else {
            cell.imageView?.image = UIImage(named: "placeHolderImage")
        }
        cell.textLabel?.text = thisRecord.title
        cell.detailTextLabel?.text = thisRecord.shortDescription
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedIndexPath = indexPath
        self.performSegueWithIdentifier("segueShowDetails", sender: self)
    }
    
    // MARK: - xml load
    private func loadRSSData(){
        var results: Dictionary<String, Array<String>> = Dictionary()
        
        self.spinner.startAnimating()
//        Alamofire.request(.GET, "http://www.mocky.io/v2/5738c0d10f0000f601b121c4")
        Alamofire.request(.GET, "http://news.google.com/?output=rss")
            .validate(statusCode: 200..<300)
            .responseString { response in
                if let xmlString = response.result.value {
                    results = XMLParser.sharedParser.decode(xmlString)
                    self.populateRssRecordListWithResults(results)
                    self.spinner.stopAnimating()
                    dispatch_async(dispatch_get_main_queue(), { self.tableView.reloadData() })
                }
        }
    }
    
    func populateRssRecordListWithResults(results: Dictionary<String, Array<String>>) {
        for (key, values) in results {
            for (index, value) in values.enumerate() {
                if key == "title" {
                    self.rssRecordList.append(RssRecord(title: value, imageUrl: "", shortDescription: "", link:  ""))
                } else if key == "url" {
                    self.rssRecordList[index].imageUrl = value
                    self.getNetworkImage(value)
                } else if key == "description" {
                    self.rssRecordList[index].shortDescription = value
                } else if key == "link" {
                    self.rssRecordList[index].link = value
                }
            }
            
        }
    }
    
    func getNetworkImage(urlString: String) -> (Request) {
        return Alamofire.request(.GET, urlString).responseImage { (response) -> Void in
            guard let image = response.result.value else { return }
            self.cacheImage(image, urlString: urlString)
        }
    }
    
    //MARK: = Image Caching
    
    func cacheImage(image: Image, urlString: String) {
        imageCache.addImage(image, withIdentifier: urlString)
    }
    
    func getCachedImage(urlString: String) -> Image? {
        return imageCache.imageWithIdentifier(urlString)
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueShowDetails" {            
            self.tableView.deselectRowAtIndexPath(self.selectedIndexPath, animated: true)
            
            let destViewController = segue.destinationViewController as! RssDetailsViewController
            
            destViewController.navigationItem.title = self.rssRecordList[self.selectedIndexPath.row].title
            
            destViewController.link = self.rssRecordList[self.selectedIndexPath.row].link
            
        }
        
    }

}

