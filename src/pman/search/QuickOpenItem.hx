package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.media.MediaSource;

enum QuickOpenItem {
    QOMedia(src : MediaSource);
    QOPlaylist(name : String);
}
