
## PMan 

---

PMan is a desktop media player/manager, written in the [Haxe](http://haxe.org) language, running on [Electron](http://electron.atom.io).
PMan's goal is to be as complete as possible as a media player/viewer, but also to provide media management/networking/organizational utilities to the user,
as well as basic editing features.


PMan is still very much a work in progress, but for standard media viewing, it is *(mostly)* stable. If you're interested in giving it a go,
you can download any one of the official releases, or build and run from source. There's no mac support yet, as I have no mac on which to test or build, but I'm hoping
to be able to add support soon. 

 If you're interested in the project, and would like to see it keep moving forward, please consider checking out [PMan's patreon page](http://www.patreon.com/pman).
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
- audio visualizations when playing music files
- progress through media is saved, so that the user can resume to that position next time that media is opened
- create bookmarks attached to a Track, allowing for quick navigation to one or more specific time offsets in the media
- tracks can be favorited. Favorited tracks are highlighted in the playlist view
- multiple tabs with distinct playlists
- organize and categorize media by tags, actors (or actresses), creator of media, content rating, and more
- capture snapshots of visual media
<!--- stream local media to chromecast (still **very** buggy)-->

#### Planned Features

- send online media to chromecast
- stream local media to chromecast
- network machines with PMan installed over LAN, so that they can share media

---

#### Possible(?) Features

These are some features I'd love to see PMan have eventually, but that I either don't currently
know how to implement, don't have time to implement, or am simply unconvinced are feasible.

- using WebGL for the display, instead of 2D Canvas
- polyfilling some of the missing codecs with pure-Haxe implementations
- stream media via AirPlay
- scriptability, or support for extensions

