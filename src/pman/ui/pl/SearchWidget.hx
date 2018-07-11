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
import pman.bg.media.MediaRow;
import pman.media.*;
import pman.search.TrackSearchEngine;
import pman.search.FileSystemSearchEngine;

import haxe.extern.EitherType as Either;

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
using tannus.FunctionTools;

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
	    // add relevant classes
	    addClass('search-widget');

        // create input row
		inputRow = new Pane();
		inputRow.addClass('input-group');
		append( inputRow );

        // create search input
		searchInput = new TextInput();
		searchInput.addClass('input-group-field');
        inputRow.append( searchInput );

        // create input button group
        var igBtnPane:Element = e('<div class="input-group-button"/>');
        inputRow.append( igBtnPane );
        searchButton = e('<input type="submit" class="button" value="go"/>');
        igBtnPane.append( searchButton );

        // create clear button
		clear = pman.display.Icons.clearIcon(64, 64, function(path) {
		    path.style.fill = player.theme.primary.toString();
		}).toFoundationImage();
		clear.addClass('clear');
		append( clear );

        // create options row
		optionsRow = new FlexRow([6, 6]);
		optionsRow.addClass('options-row');
		append( optionsRow );

		srcSelect = new Select();
		srcSelect.option('Current Playlist', 'pl');
		srcSelect.option('All Media', 'all');
		var col = optionsRow.pane( 1 );
		col.addClass('right');
		col.append( srcSelect );

        // create sort <select/>
		sortSelect = new Select();
		options(sortSelect, [
		    'None' => '',
		    'Title (ascending)' => 'aa',
		    'Title (descending)' => 'ad',
		    'Shortest' => 'da',
		    'Longest' => 'dd',
		    'Newest' => 'ca',
		    'Oldest' => 'cd',
		    'Date Modified (ascending)' => 'md',
		    'Date Modified (descending)' => 'ma',
		    'Rating (ascending)' => 'ra',
		    'Rating (descending)' => 'rd',
		    'Views (ascending)' => 'va',
		    'Views (descending)' => 'vd'
		]);
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
	public function submit(?done: VoidCb):Void {
	    done = done.nn();

	    function end(q: Playlist) {
	        player.session.setPlaylist( q );
	        defer(function() {
	            update();
	            done();
	        });
	    }

	    // get search data
		var d:SearchData = getData();
		ensure_loaded(player.session.playlist.toArray(), true, null).then(function() {
            performSearch(d, null).then(
                function(newQueue) {
                    if (d.sort != null) {
                        evalQueueSort(d.sort, newQueue).then(function(newQueue) {
                            end( newQueue );
                        }, done.raise());
                    }
                    else {
                        end( newQueue );
                    }
                },
                done.raise()
            );
        }, done.raise());
	}

    /**
      perform a search operation
     **/
	function performSearch(search:SearchData, ?queue:Playlist):Promise<Playlist> {
	    if (queue == null)
	        queue = player.session.playlist;

	    return new Promise(function(resolve, reject) {
	        if (search.term.hasContent()) {
	            switch search.source {
                    case CurrentPlaylist:
                        var matches = searchCurrentPlaylist(search, queue);
                        resolve( matches );

                    case AllMedia:
                        searchAllMedia(search, queue).then(function(matches) {
                            resolve( matches );
                        }, reject);
	            }
	        }
            else {
                resolve(queue.getRootPlaylist());
            }
	    });
	}

    /**
      perform a search on the current media-queue
     **/
	function searchCurrentPlaylist(search:SearchData, queue:Playlist):Playlist {
        // create a search engine
        var engine = new TrackSearchEngine();
        // enable engine's strictness
        engine.strictness = 1;
        // make search case-insensitive
        engine.caseSensitive = false;
        // set engine's context
        engine.setContext(queue.getRootPlaylist().toArray());
        // set engine's search term
        engine.setSearch( search.term );
        // calculate search results
        var matches = engine.getMatches();
        // sort the results by relevancy
        matches.sort(function(x, y) {
            return -Reflect.compare(x.score, y.score);
        });
        // build playlist from results
        var results:Playlist = new Playlist(matches.map.fn( _.item ));
        results.parent = queue.getRootPlaylist();
        return results;
	}

	/**
	  perform a search on all media files on the current machine
	 **/
	function searchAllMedia(search:SearchData, queue:Playlist):Promise<Playlist> {
	    return new Promise(function(accept, reject) {
	        // create and configure engine
            var engine = new FileSystemSearchEngine();
            engine.strictness = 1;
            engine.caseSensitive = false;

            // get all media paths
            var amp = _getAllMediaPaths();
            amp.then(function(allPaths: Set<Path>) {
                // configure engine context
                engine.setContext(allPaths.toArray());
                engine.setSearch( search.term );

                // get results
                var matches = engine.getMatches();
                matches.sort((x, y)-> -Reflect.compare(x.score, y.score));

                // convert match-items to tracks
                var flc = new FileListConverter();
                var results:Playlist = flc.convert(matches.map.fn(new File(_.item)));
                results.parent = queue.getRootPlaylist();

                accept( results );
            });
            amp.unless( reject );
        });
	}

	/**
	  * apply [sort] to the currently active playlist
	  */
	private function apply_sorting(sort:MediaSort, ?queue:Playlist, ?done:VoidCb):VoidPromise {
	    done = done.nn();
	    if (queue == null)
            queue = player.session.playlist;

        return new VoidPromise(function(resolve, reject) {
            evalQueueSort(sort, queue)
                .then(function(queue) {
                    //var pl = new Playlist( tracks );
                    player.session.setPlaylist( queue );

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
	function evalQueueSort(sort:MediaSort, ?queue:Playlist, ?done:Cb<Playlist>):Promise<Playlist> {
	    done = done.nn();
	    if (queue == null)
	        queue = player.session.playlist;
	    var sorter = sortLambda( sort );

	    return new Promise(function(accept, reject) {
	        ensure_loaded(queue.toArray(), true, function(?error) {
	            if (error != null) {
	                reject( error );
	            }
                else {
                    try {
                        //tracks.sort( sorter );
                        //accept( tracks );
                        queue.sort( sorter );
                        accept( queue );
                    }
                    catch (error: Dynamic) {
                        reject( error );
                    }
                }
	        });
	    }).toAsync( done );
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
      get all media rows in the database
     **/
	private function _getAllMediaRows(?on_row: MediaRow->Void):ArrayPromise<MediaRow> {
	    if (on_row == null)
	        on_row = untyped (row -> row._id);

        return new Promise(function(accept, reject) {
            var results:Array<MediaRow> = new Array();
            database.mediaStore.eachRow(function(row: MediaRow) {
                results.push( row );
                on_row( row );
            })
            .then(
                function() {
                    accept( results );
                },
                function(error) {
                    reject( error );
                }
            );
        }).array();
	}

	/**
	  * get the paths to all media files in the user's media libraries
	  */
	private function _getAllMediaPaths():Promise<Set<Path>> {
	    // all paths
        var paths:Set<Path> = new Set();
        var a:FileFilter = FileFilter.AUDIO,
        v:FileFilter = FileFilter.VIDEO,
        p:FileFilter = FileFilter.PLAYLIST,
        i:FileFilter = FileFilter.IMAGE;

        // check whether [path] matches any of the acceptible file-filters
        inline function _test_(path: Path):Bool {
            var str:String = path.toString();
            return (v.test( str ) || a.test( str ) || p.test( str ) || i.test( str ));
        }

        // descend through the given Directory
	    function _walk_(dir: Directory):Void {
	        // iterate over every entry in [dir]
	        for (entry in dir) {
	            switch ( entry.type ) {
	                /* file entries */
                    case File( file ):
                        if (_test_( file.path )) {
                            paths.push( file.path );
                        }

                    /* directory entries */
                    case Folder( folder ):
                        _walk_( folder );
	            }
	        }
	    }

        // promise results
	    return new Promise(function(accept, reject) {
            /* handle successful retrieval of [sources] */
	        function on_sources(sources: Array<Path>) {
	            for (src in sources) {
	                _walk_(new Directory( src ));
	            }
	            accept( paths );
	        }

	        player.app.appDir.getMediaSources.toPromise().then(
                on_sources,
                reject
	        );
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
            case 'c': MSDate(MDCreated, bool());
            case 'm': MSDate(MDModified, bool());
            case 'v': MSViews(bool());
            case ''|_: MSNone;
	    };
	}

	static function mediaSortToString(ms: MediaSort):String {
	    inline function bool(v: Bool):Char {
	        return (v ? 'a' : 'd');
	    }

	    return switch ms {
            case MSNone: '';
            case MSTitle(v): ('a' + bool(v));
            case MSDuration(v): ('d' + bool(v));
            case MSRating(v): ('r' + bool(v));
            case MSDate(d, v): ((switch d {
                case MDCreated: 'c';
                case MDModified: 'm';
            }) + bool(v));
            case MSViews(v): ('v' + bool(v));
	    };
	}

	static inline function invertSort<T>(sort: (a:T, b:T)->Int):(a:T, b:T)->Int {
	    return (function(a:T, b:T):Int {
	        return -sort(a, b);
	    });
	}

	static inline function boolSort<T>(value:Bool, sort:(a:T, b:T)->Int):(a:T, b:T)->Int {
	    return (value ? invertSort( sort ) : sort);
	}

	static inline function trackDataSort(sort:(a:TrackData, b:TrackData)->Int):(a:Track, b:Track)->Int {
	    return (function(a:Track, b:Track):Int {
	        return sort(a.data, b.data);
	    });
	}

    /**
      convert a MediaSort value into a sorting function
     **/
	static dynamic function sortLambda(sort: MediaSort):(a:Track, b:Track)->Int {
	    inline function bs(v, f) {
	        return boolSort(v, f);
	    }

	    inline function tds(f)
	        return trackDataSort( f );

	    var tmr:Track->String = (t -> (t.uri + (t.mediaId != null ? ('|' + t.mediaId) : ''))),
	    tmra:Array<Track>->String = (a -> a.map(tmr).join(',')),
	    tmr2:Track->Track->String = fn(tmra([_1, _2]));

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
                    var res:Float = (x.data.views / 2);
                    if (x.data.rating != null) {
                        res += (x.data.rating * 5);
                    }
                    return res;
                }

                return (function(rating) {
                    return bs(asc, function(a:Track, b:Track) {
                        return Reflect.compare(rating(a), rating(b));
                    });
                }(rating.memoize(tmr)));

            /* sort by date */
            case MSDate(type, asc):
                function stat(track: Track):FileStat {
                    return Fs.stat(track.getFsPath());
                }
                stat = stat.memoize( tmr );

                var time:Track->Date = (function(stat:(track:Track)->FileStat):Track->Date {
                    return (function(type: MediaDate):(stat:FileStat)->Date {
                        return switch type {
                            case MDCreated: (stat -> stat.ctime);
                            case MDModified: (stat -> stat.mtime);
                        };
                    }(type))
                    .wrap(function(_, track:Track) {
                        return _(stat(track));
                    })
                    .memoize( tmr );
                }(stat));
                function ttime(track: Track):Float {
                    return time(track).getTime();
                }

                return bs(asc, (function(a:Track, b:Track) {
                    return Reflect.compare(ttime(a), ttime(b));
                }));

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

    /**
      append many options to [select] at once
     **/
	static inline function options<T>(select:Select<T>, opts:Map<String, T>):Select<T> {
	    for (text in opts.keys()) {
	        select.option(text.trim(), opts[text]);
	    }
	    return select;
	}

    /**
      initialize [this] class
     **/
	public static function __init__():Void {
	    sortLambda = sortLambda.memoize();
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

