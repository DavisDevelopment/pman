package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.ext.FileFilter;

import pman.core.*;
import pman.format.m3u.Reader as M3UReader;
import pman.format.xspf.Reader as XSPFReader;
import pman.format.pls.Reader as PLSReader;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * class used to convert a list of Files into a list of Tracks
  */
class FileListConverter {
	/* Constructor Function */
	public function new():Void {

	}

/* === Instance Methods === */
	
	/**
	  * convert the given list of files into a Playlist
	  */
	public function convert(files : Array<File>):Playlist {
		fl = files;
		pl = new Playlist();

		for (file in fl) {
			_import( file );
		}

		return pl;
	}

	/**
	  * import the given file into the playlist, in the way most appropriate depending on the file
	  */
	private function _import(file : File):Void {
	    // get the normalized path
	    var path:Path = file.path.normalize();

	    // audio files
	    if (FileFilter.AUDIO.test( path )) {
	        audio_file( file );
	    }
        else if (FileFilter.VIDEO.test( path )) {
            video_file( file );
        }
        else if (FileFilter.IMAGE.test( path )) {
            image_file( file );
        }
        else if (FileFilter.PLAYLIST.test( path )) {
            playlist_file( file );
        }
        else {
            return ;
        }
	}

    /**
      * import a Playlist file
      */
	private function playlist_file(file : File):Void {
	    switch (file.path.extension.toLowerCase()) {
	        // M3U Format
            case 'm3u':
                m3u_file( file );

            // XSPF File
            case 'xspf':
                xspf_file( file );

            // PLS File
            case 'pls':
                pls_file( file );

            // anything else
            default:
                return ;
	    }
	}

    /**
      * import a pls file
      */
    private inline function pls_file(file : File):Void {
        addMany(pman.format.pls.Reader.run(file.read()));
    }

    /**
      * import an xspf file
      */
    private inline function xspf_file(file : File):Void {
        var reader = new pman.format.xspf.Reader();
        addMany(reader.read(file.read()));
    }

    /**
      * import an m3u file
      */
	private inline function m3u_file(file : File):Void {
	    addMany(pman.format.m3u.Reader.run(file.read()));
	}

    /**
      * add all items in [i]
      */
	private function addMany(i : Iterable<Track>):Void {
	    for (t in i) {
	        addTrack( t );
	    }
	}

	/**
	  * import a media file
	  */
	private inline function media_file(file : File):Void {
	    addMediaProvider(cast new LocalFileMediaProvider( file ));
	}

	/**
	  * import audio file
	  */
	private inline function audio_file(file : File):Void {
	    media_file( file );
	}

    /**
      * import video file
      */
	private inline function video_file(file : File):Void {
	    media_file( file );
	}

    /**
      * import image file
      */
	private inline function image_file(file : File):Void {
	    media_file( file );
	}

    /**
      * intelligently convert [what] into a Track and add it to the playlist
      */
	private function add(what : Dynamic):Void {
	    if (Std.is(what, MediaProvider)) {
	        addMediaProvider( what );
	    }
        else if (Std.is(what, Track)) {
            addTrack( what );
        }
	}

    /**
      * add a MediaProvider to the playlist
      */
    private inline function addMediaProvider(provider : MediaProvider):Void {
        addTrack(track( provider ));
    }

    /**
      * add a Track to the playlist
      */
	private inline function addTrack(track : Track):Void {
	    pl.push( track );
	}

    /**
      * create and return a Track
      */
	private inline function track(mp : MediaProvider) {
	    return new Track( mp );
	}

/* === Instance Fields === */

	private var fl : Array<File>;
	private var pl : Playlist;
}
