//
//  RssRecord.swift
//  RssFeedReeder
//
//  Created by Sherief Gharraph on 5/11/16.
//  Copyright © 2016 Sherief. All rights reserved.
//

import Foundation


class RssRecord {
    
    var title: String
    var description: String
    var link: String
    var pubDate: String
    var imageUrl: String
    
    init(){
        self.title = ""
        self.description = ""
        self.link = ""
        self.pubDate = ""
        self.imageUrl = ""
    }
    
}
