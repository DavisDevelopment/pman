
## PMan 
[Grab a Release](https://github.com/DavisDevelopment/pman/releases/latest)

---

PMan is a desktop media player/manager, written in the [Haxe](http://haxe.org) language, running on [Electron](http://electron.atom.io).
PMan's goal is to be as complete as possible as a media player/viewer, but also to provide media management/networking/organizational utilities to the user,
as well as basic editing features.


PMan is still very much a work in progress, but for standard media viewing, it's stable most of the time. If you're interested in giving it a go,
you can download any one of the official releases ([latest](https://github.com/DavisDevelopment/pman/releases/latest)),
or build and run from source. There's no mac support yet, as I have no mac on which to test or build, but I'm hoping to be able to add support soon.

 If you're interested in the project, and would like to see it keep moving forward, please consider heading over to the [SourceForge Page](https://sourceforge.net/projects/pman-player/)
and maybe leaving a review/rating. The feedback is much appreciated. If you're **very** interested in the project, maybe check out [PMan's patreon page](http://www.patreon.com/pman).
Even very small pledges help a lot; if not for funding, at least for motivation. 

---

#### Features

- view/play audio, video, and image files from your local filesystem as well as from the web
- reasonable performance
- save your playlists, restorable from the window menu under "Playlists"
- open entire directory (always recursive, need to change that)
- drag 'n drop files **and/or** folders onto window to open them
- freely rearrange your playlist
- shuffle, repeat
- supports importing playlists in several popular formats (m3u, pls, and xspf)
- export playlists in M3U or XSPF formats
- *several* audio visualizations when playing music files
- progress through media is saved, so that the user can resume to that position next time that media is opened
- create bookmarks attached to a Track, allowing for quick navigation to one or more specific time offsets in the media
- tracks can be favorited. Favorited tracks are highlighted in the playlist view
- multiple tabs with distinct playlists
- organize and categorize media by tags, actors (or actresses), creator of media, content rating, and more
- capture snapshots of visual media
- sort queue by a variety of attributes (e.g. title, duration, rating, views, date created, date modified, etc.)
- search through current queue
- create new queue by searching entire media library
<!--- stream local media to chromecast (still **very** buggy)-->

#### Planned Features

- display media library in a gallery-line interface for browsing
- automatically convert media files that PMan cannot play into formats that PMan *can* play
- polyfill unsupported codecs with the [Media Source Extensions API](https://developer.mozilla.org/en-US/docs/Web/API/Media_Source_Extensions_API)
  - flv support (via [flv.js](https://www.npmjs.com/package/ksc-flv))
  - probably more than can be polyfilled in pure-haxe with some effort
- send online media to chromecast
- stream local media to chromecast
- stream media from one machine to another with pman
- network machines with PMan installed over LAN, so that they can share media
- scriptability, or support for extensions

---

#### Possible(?) Features

These are some features I'd love to see PMan have eventually, but that I either don't currently
know how to implement, don't have time to implement, or am simply unconvinced are feasible.

- using WebGL for the display, instead of 2D Canvas
- polyfilling unsupported codecs that cannot be supported via MSE by implementing them directly in Haxe
- stream media via AirPlay

