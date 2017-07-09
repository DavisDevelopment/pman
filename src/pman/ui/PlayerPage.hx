package pman.ui;

import tannus.io.*;
import tannus.nw.FileChooser;
import tannus.html.Element;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;
import electron.Tools.*;

import pman.core.*;
import pman.media.*;
import pman.ds.OnceSignal;

using StringTools;
using Lambda;
using Slambda;

/*
   controller for the app page that displays the media player interface
*/
class PlayerPage extends Page {
	/* Constructor Function */
	public function new(main : BPlayerMain):Void {
		super();

		addClass('ui_page');

		app = main;

		_playerCreated = new OnceSignal();

		player = new Player(app, this);
		defer( _playerCreated.announce );
	}

/* === Instance Methods === */

	/**
	  * when [this] Page opens
	  */
	override function open(body : Body):Void {
	    super.open( body );

		css['overflow'] = 'hidden';

		var win = body.application.win;
		var canvas = win.document.createCanvasElement();
		append(new Element( canvas ));
		stage = new Stage( canvas );
		stage.fill();

        player.view.stage = stage;
		player.attachToStage( stage );

        // expose values globally
        var w = app.win;
		w.expose('player', player);
		w.exposeGetter('track', Getter.create(player.track));
	}

	/**
	  * reopen [this] Page
	  */
	override function reopen(body : Body):Void {
	    super.reopen( body );

	    css.set('display', 'block');

	    stage.resume();
	    player.reopen();
	}

	/**
	  * close [this] Page
	  */
	override function close():Void {
	    css.set('display', 'none');
	    active = false;
	    player.close();
	    stage.pause();
	}

	/**
	  * open the PlaylistView
	  */
	public function openPlaylistView():Bool {
		if (playlistView == null) {
			playlistView = new PlaylistView( player );
		}
		if ( !playlistView.isOpen ) {
		    playlistView.open();
		    stage.calculateGeometry();
		    return true;
		}
		return false;
	}

	/**
	  * close the PlaylistView
	  */
	public function closePlaylistView():Void {
		if (playlistView != null) {
			playlistView.close();
			stage.calculateGeometry();
		}
	}

	/**
	  * check whether the PlaylistView is open
	  */
	public inline function isPlaylistViewOpen():Bool {
	    return (playlistView != null && playlistView.isOpen);
	}

    /**
      * toggle the visibility of the playlistView
      */
	public inline function togglePlaylistView():Void {
	    (isPlaylistViewOpen()?closePlaylistView:openPlaylistView)();
	}

    /**
      * 
      */
	public function onPlayerCreated(f : Player->Void):Void {
	    _playerCreated.await(function() {
	        f( player );
	    });
	}

	public function onPlayerReady(f : Player->Void):Void {
	    onPlayerCreated(function(p) {
	        p.onReady(function() {
	            f( p );
	        });
	    });
	}

/* === Instance Fields === */

	public var stage : Stage;
	public var player : Player;
	public var app : BPlayerMain;
	public var _playerCreated : OnceSignal;

	public var playlistView : Null<PlaylistView> = null;
}
