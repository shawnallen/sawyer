Sawyer, a River2 reader for iPad, iPhone, and iPod touch on iOS 6.1 or greater.
===================

I decided to create, in a few hours (~4), a reference application to experiment with aspects of the iOS SDK which I don't get a chance to mess around with on a daily basis.  This application uses Storyboards, the UIActivityViewController, and whatever I happen to find compelling to extend the app itself with.  As of yet, this is neither production ready or conformant to my personal coding style.

The default feed points to Dave Winer's personal River, which you may change by visiting Settings.  I'm not doing any effort to avoid odd encodings, so if the JSONP has an unescaped sequence, you're dead in the water.

Recent Changes
========

6/7/13 - Added a "Twain" button to scroll to the high-water mark to which the user last manually refreshed.  There is also a visual cue in the section which contains this high-water mark.  My intention is to push that place into iCloud, for coherency across devices.

Screenshots
========

![](https://raw.github.com/shawnallen/sawyer/master/images/sawyer.png)
![](https://raw.github.com/shawnallen/sawyer/master/images/item.png)
![](https://raw.github.com/shawnallen/sawyer/master/images/safari.png)

Many thanks to Dave Winer for River2, the prescience to produce the feed in JSON, along with the OPML Editor that it sits a top of.

External frameworks
=========================

* [ZYInstapaperActivity](https://github.com/marianoabdala/ZYInstapaperActivity) by [Mariano Abdala](https://github.com/marianoabdala)

License
=======

Copyright (c) 2013 Shawn Allen.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

