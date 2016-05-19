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
import Kanna

class RssTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSXMLParserDelegate  {
        
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let imageCache = AutoPurgingImageCache(
        memoryCapacity: 100 * 1024 * 1024,
        preferredMemoryUsageAfterPurge: 60 * 1024 * 1024
    )

    var myParser: NSXMLParser = NSXMLParser()
    var rssRecordList : [RssRecord] = [RssRecord]()
    var rssRecord : RssRecord?
    var isTagFound = [ "item": false , "title":false, "pubDate": false ,"link":false, "description":true]
    
    // MARK - View functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView	.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.rssRecordList.isEmpty {
            self.loadRSSData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    // MARK: - Table view dataSource and Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rssRecordList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("rssCell", forIndexPath: indexPath)
        let thisRecord : RssRecord  = self.rssRecordList[indexPath.row]
        cell.textLabel?.text = thisRecord.title
        cell.detailTextLabel?.text = thisRecord.pubDate
       if let cachedImage = getCachedImage(thisRecord.imageUrl){
           cell.imageView?.image =  cachedImage
       } else {
           cell.imageView?.image = UIImage(named: "placeHolderImage")
       }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("segueShowDetails", sender: self)
    }
    
    
    
    
    // MARK: - NSXML Parse delegate function
    func parserDidStartDocument(parser: NSXMLParser) {
    }

    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == "item" {
            self.isTagFound["item"] = true
            self.rssRecord = RssRecord()
            
        }else if elementName == "title" {
            self.isTagFound["title"] = true
            
        }else if elementName == "link" {
            self.isTagFound["link"] = true
            
        }else if elementName == "pubDate" {
            self.isTagFound["pubDate"] = true
            
        }else if elementName == "description" {
            self.isTagFound["description"] = true
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
        if isTagFound["title"] == true {
            self.rssRecord?.title += string
            
        }else if isTagFound["link"] == true {
            self.rssRecord?.link += string
            
        }else if isTagFound["pubDate"] == true {
            self.rssRecord?.pubDate += string
            
        }else if isTagFound["description"] == true {
            self.rssRecord?.description += string
        }
    }

    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            self.isTagFound["item"] = false
            self.parseHtmlDescriptionForImageUrls()
            self.rssRecordList.append(self.rssRecord!)
            
        }else if elementName == "title" {
            self.isTagFound["title"] = false
            
        }else if elementName == "link" {
            self.isTagFound["link"] = false
            
        }else if elementName == "pubDate" {
            self.isTagFound["pubDate"] = false
            
        }else if elementName == "description" {
            self.isTagFound["description"] = false
        }

    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        let dispatchGroup = dispatch_group_create()
        let dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        for record in rssRecordList {
            getNetworkImage(record.imageUrl, dispatchGroup: dispatchGroup, dispatchQueue: dispatchQueue)
        }
        dispatch_group_notify(dispatchGroup, dispatchQueue, {
            self.tableView.reloadData()
            self.spinner.stopAnimating()
        })
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        self.spinner.stopAnimating()
        self.showAlertMessage(alertTitle: "Error", alertMessage: "Error while parsing xml.")
    }
    

    // MARK: - Utility functions
    private func loadRSSData(){
        self.spinner.startAnimating()
        if let rssURL = NSURL(string: "http://news.google.com/?output=rss") {
            self.myParser = NSXMLParser(contentsOfURL: rssURL)!
            self.myParser.delegate = self
            self.myParser.parse()
        }
        
    }
    
    
    func parseHtmlDescriptionForImageUrls() {
        if let doc = Kanna.HTML(html: self.rssRecord!.description, encoding: NSUTF8StringEncoding) {
            if let image = doc.at_css("img") {
                if let imageSource = image["src"] {
                    self.rssRecord!.imageUrl = "http:" + imageSource
                }
                
            }
        }
        
    }
    
    func getNetworkImage(urlString: String, dispatchGroup: dispatch_group_t, dispatchQueue: dispatch_queue_t) -> Void {
        dispatch_group_enter(dispatchGroup)
        let request  = Alamofire.request(.GET, urlString)
        request.response(queue: dispatchQueue,
                         responseSerializer: Request.imageResponseSerializer(),
                         completionHandler: { (response) -> Void in
                            dispatch_group_leave(dispatchGroup)
                            guard let image = response.result.value else { return }
                            self.cacheImage(image, urlString: urlString)
        })
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
            let selectedIndexPath : [NSIndexPath] = self.tableView.indexPathsForSelectedRows!
            self.tableView.deselectRowAtIndexPath(selectedIndexPath[0], animated: true)
            let destVc = segue.destinationViewController as! RssDetailsViewController
            destVc.navigationItem.title = self.rssRecordList[selectedIndexPath[0].row].title
            destVc.link = self.rssRecordList[selectedIndexPath[0].row].link
        }
        
    }
    
    
}

