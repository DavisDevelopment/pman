package pman.ui.pl;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.sys.FSEntry;
import tannus.async.*;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.media.*;
import pman.search.TrackSearchEngine;
import pman.search.FileSystemSearchEngine;

import Slambda.fn;
import tannus.ds.SortingTools.*;
import electron.Tools.*;

using StringTools;
using Lambda;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using Slambda;
using tannus.ds.SortingTools;
using pman.media.MediaTools;
using haxe.ds.ArraySort;

class SearchWidget extends Pane {
	/* Constructor Function */
	public function new(p:Player, l:PlaylistView):Void {
		super();

		player = p;
		playlistView = l;

		build();
	}

/* === Instance Methods === */

	/**
	  * build [this]
	  */
	override function populate():Void {
	    addClass('search-widget');

		inputRow = new Pane();
		inputRow.addClass('input-group');
		append( inputRow );

		searchInput = new TextInput();
		searchInput.addClass('input-group-field');
        inputRow.append( searchInput );

        var igBtnPane:Element = new Element('<div class="input-group-button"/>');
        inputRow.append( igBtnPane );
        searchButton = new Element('<input type="submit" class="button" value="go"/>');
        igBtnPane.append( searchButton );

		clear = pman.display.Icons.clearIcon(64, 64, function(path) {
		    path.style.fill = player.theme.primary.toString();
		}).toFoundationImage();
		clear.addClass('clear');
		append( clear );

		optionsRow = new FlexRow([6, 6]);
		optionsRow.addClass('options-row');
		//optionsRow.css.set('display', 'none');
		append( optionsRow );

		srcSelect = new Select();
		srcSelect.option('Current Playlist', 'pl');
		srcSelect.option('All Media', 'all');
		//srcSelect.addClass()
		var col = optionsRow.pane( 1 );
		col.addClass('right');
		col.append( srcSelect );

		sortSelect = new Select();
		sortSelect.option('None', '');
		sortSelect.option('Title', 'a');
		sortSelect.option('Duration', 'd');
		sortSelect.option('Most Recent', 't');
		sortSelect.option('Top Rated', 'r');
		col = optionsRow.pane( 0 );
		col.addClass('left');
		col.append( sortSelect );

		__events();

		css.write({
			'width': '98%',
			'margin-left': 'auto',
			'margin-right': 'auto'
		});

		update(); 
	} 

	/**
	  * update [this]
	  */
	public function update():Void {
	    if (searchInput.getValue() != null && searchInput.getValue() != '') { 
	        clear.css.write({
	            'display': 'block'
	        });
        }
        else {
            clear.css.write({
                'display': 'none'
            });
        }
	}

	/**
	  * handle keyup events
	  */
	private function onkeyup(event : KeyboardEvent):Void {
		switch ( event.key ) {
			case Enter:
				submit((?err) -> null);
				searchInput.iel.blur();

			case Esc:
			    searchInput.iel.blur();

			default:
				null;
		}
	}

	/**
	  * the search has been 'submit'ed
	  */
	private function submit(done: VoidCb):Void {
	    // get search data
		var d:SearchData = getData();
		var results : Playlist;
		// if a search term was provided
		if (d.term != null) {
		    switch ( d.source ) {
                case CurrentPlaylist:
                    // create a search engine
                    var engine = new TrackSearchEngine();
                    // enable engine's strictness
                    engine.strictness = 1;
                    // set engine's context
                    engine.setContext(player.session.playlist.getRootPlaylist().toArray());
                    // set engine's search term
                    engine.setSearch( d.term );
                    // calculate search results
                    var matches = engine.getMatches();
                    // sort the results by relevancy
                    matches.sort(function(x, y) {
                        return -Reflect.compare(x.score, y.score);
                    });
                    // build playlist from results
                    results = new Playlist(matches.map.fn( _.item ));
                    results.parent = player.session.playlist.getRootPlaylist();
                    player.session.setPlaylist( results );
                    defer(function() {
                        update();
                        //apply_sorting(d.sort, done);
                        done();
                    });

                case AllMedia:
                    var engine = new FileSystemSearchEngine();
                    engine.strictness = 1;
                    var amp = _getAllMediaPaths();
                    amp.then(function(allPaths) {
                        engine.setContext(allPaths.toArray());
                        engine.setSearch( d.term );
                        var matches = engine.getMatches();
                        matches.sort((x,y)->-Reflect.compare(x.score,y.score));
                        var flc = new FileListConverter();
                        results = flc.convert(matches.map.fn(new File(_.item)));
                        //if (d.source != null && !d.source.match(AllMedia)) {
                            //results.parent = player.session.playlist.getRootPlaylist();
                        //}
                        player.session.setPlaylist( results );
                        defer(function() {
                            update();
                            //apply_sorting(d.sort, done);
                            done();
                        });
                    });
                    amp.unless(done.raise());
            }
		    
            //results.parent = player.session.playlist.getRootPlaylist();
            //player.session.setPlaylist( results );
            //defer(function() {
                //update();
                //apply_sorting(d.sort, done);
            //});
		}
		// if search term was empty
		else {
		    // reset track list to root
		    var pl = player.session.playlist;
		    player.session.setPlaylist(pl.getRootPlaylist());
		    defer(function() {
		        update();
                //apply_sorting(d.sort, done);
                done();
            });
		}
	}

	/**
	  * apply [sort] to the currently active playlist
	  */
	private function apply_sorting(sort:SearchSort, done:VoidCb):Void {
	    var tracks = player.session.playlist.toArray();
	    var loader = new pman.async.tasks.EfficientTrackListDataLoader(tracks, player.app.db.mediaStore);
	    loader.run(function(?error) {
	        if (error != null) {
	            done( error );
	        }
            else {
                switch ( sort ) {
                    case None:
                        //

                    case Title:
                        tracks.sort(function(a, b) {
                            return Reflect.compare(a.title, b.title);
                        });

                    case Duration:
                        tracks.sort(function(a, b) {
                            return Reflect.compare(a.data.meta.duration, b.data.meta.duration);
                        });

                    case Rating:
                        function rating(x:Track):Float {
                            var res:Float = x.data.views;
                            if (x.data.rating != null) {
                                res += x.data.rating;
                            }
                            return res;
                        }

                        tracks.sort(function(a, b) {
                            return Reflect.compare(rating(a), rating(b));
                        });

                    case MostRecent:
                        tracks.sort(function(a, b) {
                            var x = a.getFsPath(), y = b.getFsPath();
                            if (x != null && y != null) {
                                var as = Fs.stat( x ), bs = Fs.stat( y );
                                return Reflect.compare(as.ctime.getTime(), bs.ctime.getTime());
                            }
                            else {
                                return 0;
                            }
                        });
                }

                var pl = new Playlist( tracks );
                player.session.setPlaylist( pl );
                defer(function() {
                    update();
                    done();
                });
            }
        });
	}

	/**
	  * get the paths to all media files in the user's media libraries
	  */
	private function _getAllMediaPaths():Promise<Set<Path>> {
        var paths:Set<Path> = new Set();
        var a = FileFilter.AUDIO, v = FileFilter.VIDEO, p = FileFilter.PLAYLIST;

        function _test_(path: Path):Bool {
            var str = path.toString();
            return (v.test( str ) || a.test( str ) || p.test( str ));
        }

	    function _walk_(dir: Directory):Void {
	        for (entry in dir) {
	            switch ( entry.type ) {
                    case File(file):
                        var path:Path = file.path;
                        if (_test_( path )) {
                            paths.push( path );
                        }

                    case Folder(folder):
                        _walk_( folder );
	            }
	        }
	    }

	    return Promise.create({
	        player.app.appDir.getMediaSources(function(?err, ?sources) {
	            if (err != null) {
	                throw err;
	            }
                else if (sources != null) {
                    for (src in sources) {
                        _walk_(new Directory( src ));
                    }
                    return untyped paths;
                }
                else {
                    throw 'butt monkey';
                }
	        });
        });
	}

	/**
	  * get the data from [this] widget
	  */
	private function getData():SearchData {
		// get the search text
		var inputText:Null<String> = searchInput.getValue();
		if (inputText != null) {
			inputText = inputText.trim();
			if (inputText.empty()) {
				inputText = null;
			}
		}
		var _src:Null<String>, _sort:Null<String>, src:SearchSource, sort:SearchSort;
		_src = srcSelect.getValue();
        _sort = sortSelect.getValue();
        src = (switch ( _src ) {
            case 'all': AllMedia;
            case _: CurrentPlaylist;
        });
        sort = (switch ( _sort ) {
            case 'a': Title;
            case 'd': Duration;
            case 'r': Rating;
            case 't': MostRecent;
            case '', null, _: None;
        });

		return {
			term: inputText,
			sort: sort,
			source: src
		};
	}

	/**
	  * bind event handlers
	  */
	private function __events():Void {
		searchInput.on('keydown', function(event : KeyboardEvent) {
			event.stopPropogation();
		});
		searchInput.on('keyup', onkeyup);
		clear.el.on('click', function(e) {
		    clearSearch();
		});
		//submitButton.on('click', function(event : MouseEvent) {
			//submit();
		//});

		srcSelect.on('change', function(d:Delta<String>) {
		    trace( d );
		});

		sortSelect.on('change', function(d:Delta<String>) {
		    trace( d );
		});
	}

    /**
      * clear the search widget
      */
	public function clearSearch():Void {
	    searchInput.setValue( null );
	    srcSelect.setValue( 'pl' );
	    sortSelect.setValue( '' );
	    submit(function(?error) {
	        if (error != null) {
	            throw error;
	        }
	    });
	}

/* === Instance Fields === */

	public var player : Player;
	public var playlistView : PlaylistView;

	public var inputRow : Pane;
	public var searchInput : TextInput;
	public var searchButton : Element;
	public var optionsRow : FlexRow;
	public var srcSelect : Select<String>;
	public var sortSelect : Select<String>;
	public var clear : foundation.Image;
	//public var submitButton : Button;
}

/**
  * typedef for the object that holds the form data
  */
typedef SearchData = {
	?term : String,
	?source : SearchSource,
	?sort : SearchSort
};

enum SearchSource {
    CurrentPlaylist;
    AllMedia;
}

enum SearchSort {
    None;
    Title;
    Duration;
    Rating;
    MostRecent;
}
