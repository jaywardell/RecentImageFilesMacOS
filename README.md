#  RecentImageFilesMacOS

This is a package that implements a RecentFiles system for a document-based app on macOS.

As SwiftUI for macOS is implemented now, an app that is set up as a viewer app (ie one that can only view files, not write them), will set up a lot of unnecessary and confusing UI elements that indicate that the app can edit the files too.

In order to remove this chrome, you must also lose some other things, like a Recent Files list.

This package is meant to bring backa Recent Files List in a viewer application (actually it's only been tested on an image viewer application, but it should work in other contexts).

It's a pretty specific use case, but if anyone else would find it useful, it's here. 

