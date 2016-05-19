# GoogleRssReeder
- To open project use RssFeedReeder.xcworkspace file
- Application startup performance is currently very poor due to group dispatch async for the images for the news stories! this operation happens after two other asynchronous requests, which are the original url request and the parsing.
