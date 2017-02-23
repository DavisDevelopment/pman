package pman.ui;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.media.*;
import pman.media.PlaylistChange;
import pman.ui.pl.*;

using StringTools;
using Lambda;
using Slambda;

class PlaylistView extends Pane {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();

		addClasses(['right-panel', 'playlist']);

		player = p;
		tracks = new Array();

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
	}

	/**
	  * close [this] view
	  */
	public function close():Void {
		player.session.trackChanged.off( on_track_change );
		player.session.playlist.changeEvent.off( on_playlist_change );
		dispatch('close', null);
		destroy();				
	}

	/**
	  * build the contents of [this]
	  */
	override function populate():Void {
		buildRows();
		var hed = new Heading(4, 'Playlist');
		hedRow.append( hed );
		buildSearchWidget();
		buildTrackList();

		forwardEvents(['click', 'mousedown', 'mouseup', 'mousemove', 'mouseleave'], null, MouseEvent.fromJqEvent);
		on('mouseleave', function(event) {
			var dil = new Element( 'div.drop-indicator' ).toArray();
			for (di in dil) {
				di.parent( 'li' ).remove();
			}
		});
	}

	/**
	  * refresh [this] view
	  */
	public function refresh():Void {
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
		append( listRow );
	}

	/**
	  * build out the track list
	  */
	private function buildTrackList():Void {
		list = new List();
		listRow.append( list );
		list.el.plugin( 'disableSelection' );
		for (track in playlist) {
			var trackView:TrackView = new TrackView(this, track);
			if (player.track == track) {
				trackView.focused( true );
			}
			addTrack( trackView );
		}
	}

	/**
	  * tear down the track list
	  */
	private function undoTrackList():Void {
		for (track in tracks) {
			track.destroy();
		}
		tracks = new Array();
		if (list != null)
			list.destroy();
		list = null;
	}

	/**
	  * rebuild the TrackList
	  */
	public function rebuildTracks():Void {
		undoTrackList();
		buildTrackList();
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
	}

	/**
	  * react to playlist-changes
	  */
	private function on_playlist_change(change : PlaylistChange):Void {
		refresh();
	}

	private function viewFor(track : Track):Null<TrackView> {
		for (t in tracks) {
			if (t.track == track) {
				return t;
			}
		}
		return null;
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

/* === Computed Instance Fields === */

	public var session(get, never):PlayerSession;
	private inline function get_session():PlayerSession return player.session;

	public var playlist(get, never):Playlist;
	private inline function get_playlist():Playlist return session.playlist;

/* === Instance Fields === */

	public var player : Player;
	public var tracks : Array<TrackView>;

	public var hedRow : Row;
	public var searchRow : Row;
	public var searchWidget : SearchWidget;
	public var listRow : Row;
	public var list : Null<List> = null;
}
