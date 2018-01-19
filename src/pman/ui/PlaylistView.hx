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
using pman.core.ExecutorTools;

class PlaylistView extends Pane {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();

		addClasses(['right-panel', 'playlist']);

		player = p;
		tracks = new Array();
		_tc = new Map();

	    var kc = player.app.keyboardCommands;
	    if (!kc.hasModeHandler('playlist:sidebar')) {
	        kc.registerModeHandler('playlist:sidebar', keycom);
	    }

        __bind();
		build();
	}

/* === Instance Methods === */

	/**
	  * open [this] view
	  */
	public function open():Void {
		player.page.append( this );

        unbind();
        bind();

	    var kc = player.app.keyboardCommands;

		defer(function() {
            hiliteActive();
            scrollToActive();
            searchWidget.update();
		});
	}

	/**
	  * close [this] view
	  */
	public function close():Void {
		dispatch('close', null);
		unbind();
		var kc = player.app.keyboardCommands;
		//kc.mode = 'default';
	    deselectAll();
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
		
		var start = now();
		buildTrackList(function() {
		    trace('took ${now() - start}ms to build the track-list view, containing ${playlist.length} tracks');
		});

		forwardEvents(['click', 'mousedown', 'mouseup', 'mousemove', 'mouseleave'], null, MouseEvent.fromJqEvent);

        /*
        var resizeOptions = {
            handles: 'w'
        };
		el.plugin('resizable', [resizeOptions]);
		*/
	}

	/**
	  * bind events to the current Tab
	  */
	public function bind():Void {
		player.session.trackChanged.on( on_track_change );
		player.session.playlist.changeEvent.on( on_playlist_change );
	}

	/**
	  * unbind events from the current tab
	  */
	public function unbind():Void {
		player.session.trackChanged.off( on_track_change );
		player.session.playlist.changeEvent.off( on_playlist_change );
	}

	/**
	  * bind events to the Player
	  */
	private function __bind():Void {
	    player.on('tabswitching', on_tab_changing);
	    player.on('tabswitched', on_tab_changed);
	}

	/**
	  * refresh [this] view
	  */
	public function refresh(preserveScrollPos:Bool=false):Void {
	    // save the current scroll pos
        var scrollY:Float = (listRow.el.prop( 'scrollTop' ));
        if ( preserveScrollPos )
            listRow.el.data('scrollTop', scrollY);

	    // rebuild track list
	    var start = now();
		rebuildTracks(function() {
		    trace('took ${now() - start}ms to build the track-list view, containing ${playlist.length} tracks');
		});
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
	private function buildTrackList(?done:Void->Void):Void {
	    if (list == null) {
            list = new List();
            listRow.append( list );
            list.el.plugin( 'disableSelection' );
            bindList();
        }

        // build the Track list out, poo sha
        for (track in playlist) {
            var trackView:Null<TrackView> = tview( track );
            if (player.track == track) {
                trackView.focused( true );
            }
            if ( trackView.needsRebuild ) {
                trackView.build();
            }
            addTrack( trackView );
        }

        if (done != null)
            done();

		// remove scrollbar from view if there is nothing in the view
		if (playlist.length == 0) {
		    listRow.css.set('overflow-y', 'hidden');
		}
		// and add it back if there is
        else {
		    listRow.css.set('overflow-y', 'scroll');
        }
	}

	/**
	  * tear down the track list
	  */
	private function undoTrackList(?done : Void->Void):Void {
	    list.empty();
	    tracks = new Array();

		if (done != null) {
		    defer( done );
		}
	}

	/**
	  * rebuild the TrackList
	  */
	public function rebuildTracks(?done : Void->Void):Void {
		searchResultsMode = false;
		//undoTrackList(function() {
			//buildTrackList( done );
		//});
		rebuildList(playlist.array());
		if (done != null) {
		    done();
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
	public function addTrack(tv : TrackView):Void {
		tracks.push( tv );
		list.addItem( tv );
	}

	/**
	  * detach a TrackView from [this]
	  */
	public function detachTrack(view : TrackView):Void {
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
	  * hilite the active track
	  */
	public function hiliteActive():Void {
	    if (player.track == null)
	        return ;

	    for (view in tracks) {
	        view.focused(view.track == player.track);
	    }
	}

    /**
      * efficiently build out the TrackView list
      */
	public function rebuildList(ntl: Array<Track>):Void {
        var scrollY:Float = (listRow.el.prop( 'scrollTop' ));
	    var _views = tracks.copy();
		var startTime = now();
		var nodes:Array<TrackView> = ntl.map.fn(viewFor( _ ));
		nodes.reverse();
	    for (node in nodes) {
	        list.prependItem( node );
	        _views.remove( node );
	    }
	    nodes.reverse();
	    this.tracks = nodes;

	    for (v in _views) {
	        if (v.parentWidget != null)
	            v.parentWidget.detach();
            else
                v.detach();
	    }
        defer(function() {
            listRow.el.prop('scrollTop', scrollY);
        });

	    trace('rebuilt track-list in ${now() - startTime}ms');
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
		exec.task( scrollToActive );
	}

	/**
	  * react to playlist-changes
	  */
	private function on_playlist_change(change : PlaylistChange):Void {
        if (!isLocked()) {
            exec.task(refresh( true ));
        }
	}

	/**
	  * react to an impending tab-change
	  */
	private function on_tab_changing(change : Delta<PlayerTab>):Void {
	    unbind();
	}

	/**
	  * a tab-change has just occurred
	  */
	private function on_tab_changed(change : Delta<PlayerTab>):Void {
	    undoTrackList(function() {
	        defer(function() {
	            refresh();
	        });
	    });
	}

	/**
	  * delete [this]
	  */
	override function destroy():Void {
		super.destroy();
	}

    /**
      * get a TrackView by Point
      */
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
    public function viewFor(track : Track):Null<TrackView> {
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
      * get the first Track in the list of selected Tracks
      */
	public function getFirstSelectedTrack():Null<Track> {
	    return getTrackSelection().ternary(_.get( 0 ), null);
	}

    /**
      * get the last Track in the list of selected tracks
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

	/**
	  * 'lock'ing [this] view prevents it from rebuilding itself in response to every change made to the playlist
	  * mainly designed to be used prior to actions that will trigger many changes to the playlist in rapid succession
	  */
	public function lock():Void {
	    _locked = true;
	}

    /**
      * unlock [this] view
      */
	public function unlock():Void {
	    _locked = false;
	    exec.task( refresh );
	}

    /**
      * check whether [this] view is locked
      */
	public function isLocked():Bool return _locked;

    /**
      * handle incoming keyboard input when playlistview is open
      */
	private function keycom(event : KeyboardEvent):Void {
	    var kc = player.app.keyboardCommands;
	    if ( isOpen ) {
	        trace('plkeycom: ${event.key.name}');
	        switch ( event.key ) {
	            // stop selecting
                case Esc:
                    event.cancel();
                    deselectAll();

                //
                case Enter:
                    if (anySelected()) {
                        var sel = getTrackSelection();
                        if (sel.length == 1) {
                            player.openTrack(sel.get(0));
                            viewFor(sel.get(0)).selected = false;
                        }
                        else {
                            sel.invert().remove();
                        }
                    }

                case Down if (event.noMods || event.shiftKey):
                    var expand:Bool = event.shiftKey;
                    var sel = getTrackSelection();
                    if (sel == null && tracks.length > 0) {
                        //tracks[0].selected = true;
                        viewFor( player.track ).selected = true;
                    }
                    else {
                        var lastTrack = sel.get(sel.length - 1);
                        lastTrack = playlist[playlist.indexOf( lastTrack ) + 1];
                        if (lastTrack == null)
                            lastTrack = playlist[0];
                        var view = viewFor( lastTrack );
                        if (!expand)
                            deselectAll();
                        if (view != null) {
                            view.selected = true;
                        }
                    }

                case Up if (event.noMods || event.shiftKey):
                    var expand:Bool = event.shiftKey;
                    var sel = getTrackSelection();
                    if (sel == null && tracks.length > 0) {
                        //tracks[tracks.length - 1].selected = true;
                        viewFor( player.track ).selected = true;
                    }
                    else {
                        var firstTrack = sel.get( 0 );
                        firstTrack = playlist[playlist.indexOf( firstTrack ) - 1];
                        if (firstTrack == null)
                            firstTrack = playlist[playlist.length - 1];
                        var view = viewFor( firstTrack );
                        if (!expand)
                            deselectAll();
                        if (view != null) {
                            view.selected = true;
                        }
                    }

                // select all
                case LetterA if (event.ctrlKey || event.metaKey):
                    event.preventDefault();
                    untyped __js__('document.getSelection().empty()');
                    selectAll();

                default:
                    kc.handleDefault( event );
	        }
	    }
        else {
            kc.handleDefault( event );
        }
	}

/* === Computed Instance Fields === */

	public var session(get, never):PlayerSession;
	private inline function get_session():PlayerSession return player.session;

	public var tab(get, never):Maybe<PlayerTab>;
	private inline function get_tab() return session.activeTab;

	public var playlist(get, never):Null<Playlist>;
	private function get_playlist():Null<Playlist> return tab.ternary(_.playlist, null);

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
	public var focused(default, null): Bool = false;

	private var _tc : Map<String, TrackView>;
	private var _locked : Bool = false;
}
