package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.bg.media.MediaSource;

enum QuickOpenItem {
    QOMedia(src : MediaSource);
    QOPlaylist(name : String);
}
