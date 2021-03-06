Sawyer, a River2 and River3 reader for iPad, iPhone, and iPod touch on iOS 7.0 or greater.
===================

I decided to create, in a few hours (~4), a reference application to experiment with aspects of the iOS SDK which I don't get a chance to mess around with on a daily basis.  This application uses Storyboards, the UIActivityViewController, and whatever I happen to find compelling to extend the app itself with.  As of yet, this is neither production ready or conformant to my personal coding style.

The default feed points to Dave Winer's personal River, which you may change by visiting Settings.  I made a modest effort to decode/translate escaped literals.

Recent Changes
========

* 8/31/14 - Removed background URL sessions (it was just a fun experiment), fixed a couple bugs.  Wrote unescaping routines to pretty print the mangling done upstream of us.
* 5/2/14 - Background fetch complete, fixed a couple crashers, and added icons and launch images.
* 4/25/14 - Updated the storyboard, the layout, and resumed working on background fetch.  Removed Instapaper activity.  Updated to the latest TUSafariActivity.
* 7/15/13 - Updated for the minimum of iOS 7 support, and began work on iOS 7 background fetch and iCloud.  TSRiver does way too much -- so wrong.
* 6/17/13 - Changed to use UIWebView for processing the JSONP.
* 6/7/13 - Added a "Twain" button to scroll to the high-water mark to which the user last manually refreshed.  There is also a visual cue in the section which contains this high-water mark.  My intention is to push that place into iCloud, for coherency across devices.

Screenshots
========

![](https://raw.github.com/shawnallen/sawyer/master/images/sawyer.png)
![](https://raw.github.com/shawnallen/sawyer/master/images/item.png)
![](https://raw.github.com/shawnallen/sawyer/master/images/safari.png)
![](https://raw.github.com/shawnallen/sawyer/master/images/sawyer~ipad.png)
![](https://raw.github.com/shawnallen/sawyer/master/images/safari~ipad.png)

Many thanks to Dave Winer for River2 and River3, the prescience to produce the feed in JSON, along with the OPML Editor that the platform sits a top of.

External frameworks
=========================

* [TUSafariActivity](https://github.com/davbeck/TUSafariActivity) by [David Beck](https://github.com/davbeck)

License
=======

Copyright (c) 2013 Shawn Allen.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

