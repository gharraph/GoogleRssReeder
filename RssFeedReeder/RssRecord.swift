//
//  RssRecord.swift
//  RssFeedReeder
//
//  Created by Sherief Gharraph on 5/11/16.
//  Copyright © 2016 Sherief. All rights reserved.
//

import Foundation

class RssRecord {
    var imageUrl: String
    var title: String
    var shortDescription: String
    var link: String
    
    init(title: String, imageUrl: String, shortDescription: String, link: String)   {
        self.imageUrl = imageUrl
        self.shortDescription = shortDescription
        self.title = title
        self.link = link
    }
}
