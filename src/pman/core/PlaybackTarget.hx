package pman.core;

import pman.media.*;

enum PlaybackTarget {
    PTThisDevice;
    PTChromecast(ccc : ChromecastController);
}
