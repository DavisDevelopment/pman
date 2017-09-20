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

@:access( pman.edb.AppDir )
class AppDirPlaylists {
    public function new(a : AppDir) {
        appDir = a;
    }

    public function readPlaylistFile(name : String):Maybe<ByteArray> {
        return appDir.playlistFileData( name );
    }

    public function parsePlaylist(data:ByteArray):Playlist {
        var reader = new pman.format.xspf.Reader();
        return reader.read(data.toString());
    }

    public function printPlaylist(l : Playlist):ByteArray {
        return pman.format.xspf.Writer.run( l );
    }

    public function readPlaylist(name:String):Maybe<Playlist> {
        return readPlaylistFile(name).ternary(parsePlaylist(_), null);
    }

    public inline function writePlaylist(name:String, playlist:Playlist):Void {
        Fs.write(appDir.playlistPath(name), printPlaylist(playlist));
    }

    public function editSavedPlaylist(name:String, edit:Playlist->Void, ?done:VoidCb):Void {
        var playlist = readPlaylist( name );
        if (playlist == null) {
            return ;
        }
        var list = playlist.copy();
        edit( list );
        var path = appDir.playlistPath( name );
        var data = printPlaylist( list );
        Fs.write(path, data);
        if (done != null) {
            done();
        }
    }

    private var appDir : AppDir;
}
