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

import pman.core.*;
import pman.media.*;

using StringTools;
using Lambda;
using Slambda;

class PlayerPage extends Page {
	/* Constructor Function */
	public function new(main : BPlayerMain):Void {
		super();

		addClass('ui_page');

		app = main;
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

		player = new Player(app, this);
		player.attachToStage( stage );

        #if debug
		var fps = new FPSDisplay( player );
		stage.addChild( fps );
	    #end

		app.win.expose('player', player);
	}

	/**
	  * reopen [this] Page
	  */
	override function reopen(body : Body):Void {
	    super.reopen( body );

	    css.set('display', 'block');

	    stage.resume();
	}

	/**
	  * close [this] Page
	  */
	override function close():Void {
	    css.set('display', 'none');
	    active = false;
	    player.pause();
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

/* === Instance Fields === */

	public var stage : Stage;
	public var player : Player;
	public var app : BPlayerMain;

	public var playlistView : Null<PlaylistView> = null;
}
