package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.sys.*;
import tannus.sys.FileSystem in Fs;
import tannus.http.*;
import tannus.media.Duration;
import tannus.media.TimeRange;
import tannus.media.TimeRanges;
import tannus.math.Random;
import tannus.html.fs.*;
import tannus.html.fs.WebDirectoryEntry as WebDir;

import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;

import Std.*;
import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;
using pman.media.MediaTools;

class DragDropManager {
	/* Constructor Function */
	public function new(main : BPlayerMain):Void {
		app = main;
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	public function init():Void {
		bind_events();
	}

	/**
	  * bind the event handlers
	  */
	private function bind_events():Void {
		// the list of drag events being bound
		var events:Array<String> = ['dragenter', 'dragleave', 'dragover', 'dragend', 'drop'];
		var target = app.body;
		target.forwardEvents(events, null, DragDropEvent.fromJqEvent);
		target.on('dragenter', onDragEnter);
		target.on('dragleave', onDragLeave);
		target.on('dragover', onDragOver);
		target.on('dragend', onDragEnd);
		target.on('drop', onDrop);
	}

	/**
	  * when [this] manager becomes the drop target of the dragged object
	  */
	private function onDragEnter(event : DragDropEvent):Void {
	    app.player.dispatch('dragenter', event);
	}

	/**
	  * when the dragged object leaves [this] manager's area of influence
	  */
	private function onDragLeave(event : DragDropEvent):Void {
	    app.player.dispatch('dragleave', event);
	}

	/**
	  * as the dragged object is being dragged within [this] manager's area of influence
	  */
	private function onDragOver(event : DragDropEvent):Void {
		event.preventDefault();

		app.player.dispatch('dragover', event);
	}

	/**
	  * when the current drag operation is being ended
	  */
	private function onDragEnd(event : DragDropEvent):Void {
		app.player.dispatch('dragend', event);
	}

	/**
	  * when an object has just been dropped onto [this]
	  */
	private function onDrop(event : DragDropEvent):Void {
		// cancel default behavior
		event.preventDefault();
		// create the Array of Tracks
		var tracks:Array<Track> = new Array();
		var stack = new AsyncStack();
		// shorthand reference to [event.dataTransfer]
		var dt = event.dataTransfer;
		// if the DataTransfer has the [items] field
		if (dt.items != null) {
			for (item in dt.items) {
				if (item.kind == DKFile) {
				    var entry = item.getEntry();
				    if ( entry.isDirectory ) {
				        var webDir:WebDir = new WebDir(cast entry);
				        stack.push(function(next) {
                            getDirectoryPath(webDir, function(path : Path) {
                                var directory:Directory = new Directory(path.absolutize());
                                trace( directory );
                                directory.getAllOpenableFiles(function( files ) {
                                    tracks = tracks.concat(files.convertToTracks());
                                    next();
                                });
                            });
                        });
				    }
                    else {
                        var webFile = item.getFile();
                        if (webFile != null) {
                            stack.push(function(next) {
                                var file = new File(webFile.path);
                                tracks.push(Track.fromFile( file ));
                                next();
                            });
                        }
                    }
				}
				else if (item.kind == DKString) {
					trace({
						data: item.getString(),
						type: item.type
					});
				}
				else {
					continue;
				}
			}
		}
		// if it has the [files] field
		else if (dt.files != null) {
		    stack.push(function(next) {
                for (webFile in dt.files) {
                    var file:File = new File( webFile.path );
                    tracks.push(Track.fromFile( file ));
                }
                next();
            });
		}

		// load the Tracks into the Playlist
		stack.run(function() {
            app.player.addItemList(tracks, function() {
                trace( tracks );
            });
        });
	}

	/**
	  * get a Directory path from a WebDirectory
	  */
	private function getDirectoryPath(d:WebDir, f:Path->Void, level:Int=1):Void {
	    // read all entries
	    var ep = d.readEntries();
	    ep.then(function( entries ) {
	        var fileEntries:Array<WebFileEntry> = cast entries.filter.fn( _.isFile );
	        if (fileEntries.length > 0) {
	            var fileEntry:WebFileEntry = cast fileEntries[0];
	            var fp = fileEntry.file();
	            fp.then(function(webFile : WebFile) {
	                var webFilePath:Path = new Path( webFile.path );
	                var pieces = webFilePath.pieces;
	                for (i in 0...level) {
	                    pieces.pop();
	                }
	                webFilePath = Path.fromPieces( pieces );
	                f( webFilePath );
	            });
	            fp.unless(function(error) {
	                throw error;
	            });
	        }
            else if (entries.length > 0 && entries[0].isDirectory) {
                var subDir:WebDir = new WebDir(cast entries[0]);
                getDirectoryPath(subDir, f, (level + 1));
            }
            else {
                throw 'Error: Unable to resolve directory path';
            }
	    });
	    ep.unless(function( error ) {
	        throw error;
	    });
	}

/* === Instance Fields === */

	public var app : BPlayerMain;
}
