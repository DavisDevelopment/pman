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
import tannus.async.promises.*;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.bg.media.MediaSort;
import pman.bg.media.MediaFilter;
import pman.media.*;
import pman.search.TrackSearchEngine;
import pman.search.FileSystemSearchEngine;

import Slambda.fn;
import tannus.ds.SortingTools.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using Lambda;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using Slambda;
using tannus.ds.SortingTools;
using pman.media.MediaTools;
using haxe.ds.ArraySort;
using tannus.async.Asyncs;

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
		append( optionsRow );

		srcSelect = new Select();
		srcSelect.option('Current Playlist', 'pl');
		srcSelect.option('All Media', 'all');
		var col = optionsRow.pane( 1 );
		col.addClass('right');
		col.append( srcSelect );

		sortSelect = new Select();
		sortSelect.option('None', '');
		sortSelect.option('Title (ascending)', 'aa');
		sortSelect.option('Title (descending)', 'ad');
		sortSelect.option('Longest', 'da');
		sortSelect.option('Shortest', 'dd');
		sortSelect.option('Newest', 'ta');
		sortSelect.option('Oldest', 'td');
		sortSelect.option('Rating (ascending)', 'ra');
		sortSelect.option('Rating (descending)', 'rd');
		sortSelect.option('Views (ascending)', 'va');
		sortSelect.option('Views (descending)', 'vd');
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
                        player.session.setPlaylist( results );
                        defer(function() {
                            update();
                            done();
                        });
                    });
                    amp.unless(done.raise());
            }
		    
		}
		// if search term was empty
		else {
		    // reset track list to root
		    var pl = player.session.playlist;
		    player.session.setPlaylist(pl.getRootPlaylist());
		    defer(function() {
		        update();
                done();
            });
		}
	}

	function performSearch(search:SearchData, ?queue:Playlist, ?done:VoidCb):Promise<Playlist> {
	    if (queue == null)
	        queue = player.session.playlist;

	    return new Promise(function(resolve, reject) {
	        if (search.term.hasContent()) {
	            switch search.source {
                    case CurrentPlaylist:
                        //TODO

                    case AllMedia:
                        //TODO
	            }
	        }
            else {
                resolve(queue.getRootPlaylist());
            }
	    })
	}

	/**
	  * apply [sort] to the currently active playlist
	  */
	private function apply_sorting(sort:MediaSort, ?tracks:Array<Track>, ?done:VoidCb):VoidPromise {
	    done = done.nn();
	    if (tracks == null)
            tracks = player.session.playlist.toArray();

        return new VoidPromise(function(resolve, reject) {
            evalSort(sort, tracks)
                .then(function(tracks) {
                    var pl = new Playlist( tracks );
                    player.session.setPlaylist( pl );

                    update();
                    resolve();
                })
                .unless(function(error) {
                    reject( error );
                });
        }).toAsync( done );
	}

    /**
      perform the given sorting operation on the given list of Tracks
     **/
	function evalSort(sort:MediaSort, ?tracks:Array<Track>, ?done:Cb<Array<Track>>):ArrayPromise<Track> {
	    done = done.nn();
	    if (tracks == null)
	        tracks = player.session.playlist.toArray();
	    var sorter = sortLambda( sort );
	    return new Promise(function(accept, reject) {
	        ensure_loaded(tracks, function(?error) {
	            if (error != null) {
	                reject( error );
	            }
                else {
                    try {
                        tracks.sort( sorter );
                        accept( tracks );
                    }
                    catch (error: Dynamic) {
                        reject( error );
                    }
                }
	        });
	    }).toAsync( done ).array();
	}

	/**
	  ensure that all Track's data is loaded
	 **/
	function ensure_loaded(tracks:Array<Track>, all:Bool=false, ?done:VoidCb):VoidPromise {
	    return (vsequence.bind(
	        function(add, exec) {
	            for (track in tracks) {
	                if (track.data == null) {
	                    add(function(next) {
                            track.getData(function(?error, ?data) {
                                if (error != null)
                                    next(error);
                                else
                                    next();
                            });
                        });
	                }

	                if ( all ) {
	                    add(function(next) {
	                        track.data.fill( next );
                        });
	                }
	            }

	            exec();
	        },
	    _)
        .toPromise()
        .toAsync(done));
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
		var _src:Null<String> = srcSelect.getValue(),
		_sort:Null<String> = sortSelect.getValue(),
		src:SearchSource,
		sort:MediaSort = stringToMediaSort( _sort );
        src = (switch ( _src ) {
            case 'all': AllMedia;
            case _: CurrentPlaylist;
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

		srcSelect.on('change', function(d:Delta<String>) {
		    trace( d );
		});

		sortSelect.on('change', function(d:Delta<String>) {
		    var sort = stringToMediaSort( d.current );
		    apply_sorting(sort, function(?error) {
		        if (error != null) {
		            throw error;
		        }
		    });
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

    /**
      convert the given String to a MediaSort value
     **/
	static function stringToMediaSort(s: String):MediaSort {
	    if (s.empty()) {
	        return MSNone;
	    }

	    s = s.toLowerCase();
	    inline function bool() {
	        return switch (s.characterAt(1)) {
                case 'a': true;
                case 'd': false;
                case _: throw 'Wtf';
	        };
	    }

	    return switch (s.characterAt(0)) {
            case 'a': MSTitle(bool());
            case 'd': MSDuration(bool());
            case 'r': MSRating(bool());
            case 't': MSDate(bool());
            case 'v': MSViews(bool());
            case ''|_: MSNone;
	    };
	}

	static inline function invertSort<T>(sort: (a:T, b:T)->Int):(a:T, b:T)->Int {
	    return (function(a:T, b:T):Int {
	        return -sort(a, b);
	    });
	}

	static inline function boolSort<T>(value:Bool, sort:(a:T, b:T)->Int):(a:T, b:T)->Int {
	    return (value ? sort : invertSort( sort ));
	}

	static inline function trackDataSort(sort:(a:TrackData, b:TrackData)->Int):(a:Track, b:Track)->Int {
	    return (function(a:Track, b:Track):Int {
	        return sort(a.data, b.data);
	    });
	}

    /**
      convert a MediaSort value into a sorting function
     **/
	static function sortLambda(sort: MediaSort):(a:Track, b:Track)->Int {
	    inline function bs(v, f) {
	        return boolSort(v, f);
	    }
	    inline function tds(f)
	        return trackDataSort( f );

        switch sort {
            /* do not sort */
            case MSNone:
                return (function(a, b) {
                    return 0;
                });

            /* sort by title */
            case MSTitle(asc):
                return bs(asc, function(a:Track, b:Track) {
                    return Reflect.compare(a.title, b.title);
                });

            /* sort by duration */
            case MSDuration(asc):
                return bs(asc, tds(function(a:TrackData, b:TrackData) {
                    return Reflect.compare(a.meta.duration, b.meta.duration);
                }));

            /* sort by rating */
            case MSRating(asc):
                /* get an abstracted rating value */
                function rating(x: Track):Float {
                    var res:Float = x.data.views;
                    if (x.data.rating != null) {
                        res += x.data.rating;
                    }
                    return res;
                }

                return bs(asc, function(a:Track, b:Track) {
                    return Reflect.compare(rating(a), rating(b));
                });

            /* sort by date */
            case MSDate(asc):
                return bs(asc, function(a:Track, b:Track) {
                    var x = a.getFsPath(), y = b.getFsPath();
                    if (x != null && y != null) {
                        var as = Fs.stat( x ), bs = Fs.stat( y );
                        return Reflect.compare(as.ctime.getTime(), bs.ctime.getTime());
                    }
                    else {
                        return 0;
                    }
                });

            /* sort by views */
            case MSViews(asc):
                return bs(asc, function(a:Track, b:Track) {
                    return Reflect.compare(a.data.views, b.data.views);
                });

            /* unexpected value */
            case _:
                throw 'BETTY';
        }
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
	public var filterSelect : Select<MediaFilter>;
	public var clear : foundation.Image;
	//public var submitButton : Button;
}

/**
  * typedef for the object that holds the form data
  */
typedef SearchData = {
	?term : String,
	?source : SearchSource,
	?sort : MediaSort
};

enum SearchSource {
    CurrentPlaylist;
    AllMedia;
}

