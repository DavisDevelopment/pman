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
import Slambda.fn;

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
		var events:Array<String> = ['dragenter', 'dragleave', 'dragover', 'dragend'];
		var target = app.body;
		var mapper = fn(new PlayerDragDropEvent(DragDropEvent.fromJqEvent(_)));
		target.forwardEvents(events, null, mapper);
		target.forwardEvent('drop', null, DragDropEvent.fromJqEvent);
		target.on('dragenter', onDragEnter);
		target.on('dragleave', onDragLeave);
		target.on('dragover', onDragOver);
		target.on('dragend', onDragEnd);
		target.on('drop', onDrop);
	}

	/**
	  * when [this] manager becomes the drop target of the dragged object
	  */
	private function onDragEnter(event : PlayerDragDropEvent):Void {
	    app.player.dispatch('dragenter', event);
	    trace('drag-enter');
	}

	/**
	  * when the dragged object leaves [this] manager's area of influence
	  */
	private function onDragLeave(event : PlayerDragDropEvent):Void {
	    app.player.dispatch('dragleave', event);
	    trace('drag-leave');
	}

	/**
	  * as the dragged object is being dragged within [this] manager's area of influence
	  */
	private function onDragOver(event : PlayerDragDropEvent):Void {
		event.preventDefault();

		app.player.dispatch('dragover', event);
		trace('drag-over');
	}

	/**
	  * when the current drag operation is being ended
	  */
	private function onDragEnd(event : PlayerDragDropEvent):Void {
		app.player.dispatch('dragend', event);
		trace('drag-end');
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
			    // if the item is a FileSystem entry
				if (item.kind == DKFile) {
				    // get that entry
				    var entry = item.getEntry();
				    // if the entry points to a Directory
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
				    // otherwise it must point to a standard file
                    else {
                        // so get a reference to that file
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
		    // create new Event object
		    var playerEvent = new PlayerDragDropEvent(event, tracks);
		    
		    // dispatch the event
		    app.player.dispatch('drop', playerEvent);

            // if .preventDefault() was called on [playerEvent]
            if ( playerEvent.defaultPrevented ) {
                // do not perform default behavior
                return ;
            }

		    // function to load the tracks into the Player
		    function addem(?f : Void->Void):Void {
		        app.player.addItemList(tracks, function() {
		            trace('${tracks.length} tracks were dropped onto the window');
		            if (f != null)
		                defer( f );
		        });
		    }

            var askNewTab = true;
            if ( askNewTab ) {
                // ask user if they'd like to open the dragged items in a new tab
                app.player.confirm('Would you like to open these items in a new tab?', function(answerIsYes) {
                    if ( answerIsYes ) {
                        // save the current tab index
                        var cti = app.player.session.activeTabIndex;
                        // get the index of the newly created tab
                        var nti = app.player.session.newTab();
                        // switch to the new tab
                        app.player.session.setTab( nti );
                        // load in the tracks
                        addem(function() {
                            // then switch back to the original tab
                            app.player.session.setTab( cti );
                        });
                    }
                    else {
                        addem();
                    }
                });
            }
            else {
                addem();
            }
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
