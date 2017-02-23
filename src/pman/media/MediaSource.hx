package pman.media;

import tannus.sys.Path;
import tannus.http.Url;

enum MediaSource {
	MSLocalPath(path : Path);
	MSUrl(url : String);
}
