package pman.edb;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.tuples.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;

import electron.ext.*;
import electron.Tools.*;

#if renderer_process

import pman.core.*;
import pman.media.Playlist;
import pman.Globals.*;
import pman.edb.AppDirPlaylists;

#end

import pman.core.JsonData;
import pman.core.PlayerPlaybackProperties;
import pman.async.*;

import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Template;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

@bind(
    'autoPlay',
    'autoRestore',
    'showAlbumArt',
    'showSnapshot',
    'directRender'
)
class Preferences extends JsonFileStorage {
    public function new():Void {
        super(new AppDir().preferencesPath());
    }

    public var autoPlay:Bool = false;
    public var autoRestore:Bool = false;
    public var showAlbumArt:Bool = false;
    public var showSnapshot:Bool = true;
    public var directRender:Bool = true;
}
