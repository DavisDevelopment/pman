package pman.ui;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import electron.Tools.*;
import pman.Globals.*;

import pman.core.*;
import pman.media.*;
import pman.media.PlaylistChange;
import pman.ui.pl.*;
import pman.search.Match as SearchMatch;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using Slambda;
using tannus.ds.ArrayTools;

class PlaylistView extends Pane {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();

		addClasses(['right-panel', 'playlist']);

		player = p;
		tracks = new Array();
		_tc = new Map();

		build();
	}

/* === Instance Methods === */

	/**
	  * open [this] view
	  */
	public function open():Void {
		player.page.append( this );

		player.session.trackChanged.on( on_track_change );
		player.session.playlist.changeEvent.on( on_playlist_change );

		defer(function() {
            //searchWidget.searchInput.focus();
            scrollToActive();
            searchWidget.update();
		});
	}

	/**
	  * close [this] view
	  */
	public function close():Void {
		player.session.trackChanged.off( on_track_change );
		player.session.playlist.changeEvent.off( on_playlist_change );
		dispatch('close', null);
		detach();
	}

	/**
	  * build the contents of [this]
	  */
	override function populate():Void {
		buildRows();
		/*
		var hed = new Heading(4, 'Playlist');
		hed.css['color'] = 'white';
		if (player.session.name != null) {
		    hed.text = player.session.name;
		}
		hedRow.append( hed );
		*/

		buildSearchWidget();
		buildTrackList();

		forwardEvents(['click', 'mousedown', 'mouseup', 'mousemove', 'mouseleave'], null, MouseEvent.fromJqEvent);

        /*
        var resizeOptions = {
            handles: 'w'
        };
		el.plugin('resizable', [resizeOptions]);
		*/
	}

	/**
	  * refresh [this] view
	  */
	public function refresh(preserveScrollPos:Bool=false):Void {
	    // save the current scroll pos
        var scrollY:Float = listRow.el.prop('scrollTop');
        if (preserveScrollPos)
            listRow.el.data('scrollTop', scrollY);
	    // rebuild track list
		rebuildTracks();
	}

	/**
	  * build out the rows
	  */
	private function buildRows():Void {
		hedRow = new Row();
		append( hedRow );
		searchRow = new Row();
		searchRow.addClass('search-box');
		append( searchRow );
		listRow = new Row();
		listRow.addClass('tracks');
		append( listRow );
	}

	/**
	  * build out the track list
	  */
	private function buildTrackList():Void {
		list = new List();
		listRow.append( list );
		list.el.plugin( 'disableSelection' );
		bindList();
		for (track in playlist) {
			var trackView:TrackView = tview( track ); 
			if (player.track == track) {
				trackView.focused( true );
			}
			if ( trackView.needsRebuild ) {
			    trackView.build();
			}
			addTrack( trackView );
		}
		if (playlist.length == 0) {
		    listRow.css.set('overflow-y', 'hidden');
		}
        else {
		    listRow.css.set('overflow-y', 'scroll');
        }
		defer(function() {
		    scrollToActive();
		});
	}

	/**
	  * tear down the track list
	  */
	private function undoTrackList():Void {
		for (track in tracks) {
			detachTrack( track );
		}
		tracks = new Array();
		if (list != null) {
			list.destroy();
        }
		list = null;
	}

	/**
	  * rebuild the TrackList
	  */
	public function rebuildTracks():Void {
		searchResultsMode = false;
		undoTrackList();
		buildTrackList();
	}

	/**
	  * rebuild the TrackList to show search results
	  */
	public function showSearchResults(matches : Array<SearchMatch<Track>>):Void {
		searchResultsMode = true;
		undoTrackList();
		buildMatchList( matches );
	}

	/**
	  * build the track list for the search-results view
	  */
	private function buildMatchList(matches : Array<SearchMatch<Track>>):Void {
		list = new List();
		listRow.append( list );
		list.el.plugin('disableSelection');
		bindList();
		for (match in matches) {
		    var view = tview( match.item );
			if (player.track == match.item) {
				view.focused( true );
			}
			addTrack( view );
		}
	}

	/**
	  * build out the search widget
	  */
	private function buildSearchWidget():Void {
		searchWidget = new SearchWidget(player, this);
		searchRow.append( searchWidget );
	}

	/**
	  * add a Track to [this]
	  */
	public inline function addTrack(tv : TrackView):Void {
		tracks.push( tv );
		list.addItem( tv );
	}

	/**
	  * detach a TrackView from [this]
	  */
	public inline function detachTrack(view : TrackView):Void {
	    tracks.remove( view );
	    list.removeItemFor( view );
	}

	/**
	  * scroll to the active track
	  */
	public function scrollToActive():Void {
	    // if there is a scroll position saved
	    if (listRow.el.data('scrollTop') != null) {
	        // then restore that
	        listRow.el.prop('scrollTop', listRow.el.data('scrollTop'));
	        listRow.el.removeData('scrollTop');
	        return ;
	    }
	    if (player.track == null)
	        return ;
	    var active:Null<TrackView> = viewFor( player.track );
	    if (active == null)
	        return ;

	    var vr = rect();
	    vr.y += listRow.el.scrollTop();
	    var ar = active.rect();
	    var visible:Bool = active.el.plugin('isOnScreen');
	    if ( !visible ) {
	        // the center of the viewport
	        var y:Float = (ar.y - (vr.h / 3));
	        listRow.el.scrollTop( y );
	    }
	}

	/**
	  * create or get a TrackView for the given Track
	  */
	private function tview(t : Track):TrackView {
	    if (_tc.exists( t.uri )) {
	        return _tc[t.uri];
	    }
        else {
            var view = new TrackView(this, t);
            _tc[t.uri] = view;
            return view;
        }
	}

	/**
	  * react to 'track-change' events
	  */
	private function on_track_change(delta : Delta<Null<Track>>):Void {
		if (delta.previous != null) {
			var pv = viewFor( delta.previous );
			if (pv != null) {
				pv.focused( false );
			}
		}
		if (delta.current != null) {
			var cv = viewFor( delta.current );
			if (cv != null) {
				cv.focused( true );
			}
		}
		defer( scrollToActive );
	}

	/**
	  * react to playlist-changes
	  */
	private function on_playlist_change(change : PlaylistChange):Void {
        refresh( true );
	}

	

	/**
	  * delete [this]
	  */
	override function destroy():Void {
		super.destroy();
	}

	@:allow( pman.ui.pl.TrackView )
	private function findTrackViewByPoint(p : Point):Null<TrackView> {
		var lastPassed:Null<{t:TrackView, r:Rectangle}> = null;
		for (t in tracks) {
			var tr = t.rect();
			if (tr.containsPoint( p )) {
				return t;
			}
			else if (p.y > tr.y) {
				lastPassed = {t:t, r:tr};
			}
		}
		if (lastPassed != null) {
			return lastPassed.t;
		}
		else return null;
	}

    /**
      * bind events to the list
      */
	private function bindList():Void {
	    if (list != null) {
	        list.forwardEvents(['mousemove', 'mouseleave', 'mouseenter'], null, MouseEvent.fromJqEvent);
	    }

	    var sortOptions = {
            update: function(event, ui) {
                var item:Element = ui.item;
                var t:TrackView = item.children().data( 'view' );
                playlist.move(t.track, (function() return getIndexOf( t )));
            }
	    };
	    list.el.plugin('sortable', [sortOptions]);
	}

    /**
      * get the TrackView associated with the given Track
      */
    public inline function viewFor(track : Track):Null<TrackView> {
        return _tc[track.uri];
    }

    /**
      * get the index of the given TrackView
      */
	public function getIndexOf(t : TrackView):Int {
	    var lis:Element = new Element(list.el.children());
	    for (index in 0...lis.length) {
	        var li:Element = new Element(lis.at( index ));
	        var view:Null<TrackView> = li.children().data('view');
	        if (view != null && Std.is(view, TrackView) && view == t) {
	            return index;
	        } 
	    }
	    return -1;
	}

	/**
	  * select Tracks
	  */
	public function selectTracks(f : TrackView -> Bool):Null<TrackSelection> {
	    var list:Array<TrackView> = new Array();
	    for (t in tracks) {
	        if (t.selected = f( t )) {
	            list.push( t );
	        }
	    }
	    if (list.length > 0) {
	        return new TrackSelection(playlist, list.map.fn(_.track));
	    }
        else {
            return null;
        }
	}

	/**
	  * apply a pre-constructed selection
	  */
	public function applySelection(selection : TrackSelection):Void {
	    selectTracks.fn(selection.has( _.track ));
	}

	/**
	  * select all tracks
	  */
	public function selectAll():Null<TrackSelection> {
	    return selectTracks.fn(tv=>true);
	}

	/**
	  * deselect all tracks
	  */
	public function deselectAll():Null<TrackSelection> {
	    return selectTracks.fn(tv=>false);
	}

	/**
	  * check if any Tracks are selected
	  */
	public function anySelected():Bool {
	    return tracks.any.fn( _.selected );
	}

	/**
	  * get the list of TrackViews that are selected
	  */
	public function getSelectedTrackViews():Array<TrackView> {
	    return tracks.filter.fn(_.selected);
	}

	/**
	  * get the list of Tracks that are selected
	  */
	public function getSelectedTracks():Array<Track> {
	    return getSelectedTrackViews().map.fn( _.track );
	}

	/**
	  * get the current Track selection
	  */
	public function getTrackSelection():Maybe<TrackSelection> {
	    var selectedTracks = getSelectedTracks();
	    if (selectedTracks.length > 0) {
	        return new TrackSelection(playlist, selectedTracks);
	    }
        else return null;
	}

    /**
      *
      */
	public function getFirstSelectedTrack():Null<Track> {
	    return getTrackSelection().ternary(_.get( 0 ), null);
	}

    /**
      *
      */
	public function getLastSelectedTrack():Null<Track> {
	    return getTrackSelection().ternary(_.get(_.length - 1), null);
	}

	/**
	  * set the 'focused' state of [this] playlist view
	  */
	public function setFocused(value : Bool):Bool {
	    var ret = (focused = value);
	    return ret;
	}

/* === Computed Instance Fields === */

	public var session(get, never):PlayerSession;
	private inline function get_session():PlayerSession return player.session;

	public var playlist(get, never):Playlist;
	private inline function get_playlist():Playlist return session.playlist;

	public var isOpen(get, never):Bool;
	private inline function get_isOpen():Bool {
	    return childOf( 'body' );
	}

/* === Instance Fields === */

	public var player : Player;
	public var tracks : Array<TrackView>;
	public var searchResultsMode : Bool = false;

	public var hedRow : Row;
	public var searchRow : Row;
	public var searchWidget : SearchWidget;
	public var listRow : Row;
	public var list : Null<List> = null;

	private var _tc : Map<String, TrackView>;
}
