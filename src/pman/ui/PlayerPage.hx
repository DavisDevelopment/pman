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
		css['overflow'] = 'hidden';

		var win = body.application.win;
		var canvas = win.document.createCanvasElement();
		append(new Element( canvas ));
		stage = new Stage( canvas );
		stage.fill();

		player = new Player(app, this);
		player.attachToStage( stage );

		app.win.expose('player', player);
	}

	/**
	  * open the PlaylistView
	  */
	public function openPlaylistView():Bool {
		if (playlistView == null) {
			playlistView = new PlaylistView( player );
			playlistView.open();
			playlistView.once('close', untyped function() {
				playlistView = null;
			});
			stage.calculateGeometry();
			return true;
		}
		else {
			return false;
		}
	}

	/**
	  * close the PlaylistView
	  */
	public function closePlaylistView():Void {
		if (playlistView != null) {
			playlistView.close();
		}
	}

/* === Instance Fields === */

	public var stage : Stage;
	public var player : Player;
	public var app : BPlayerMain;

	public var playlistView : Null<PlaylistView> = null;
}
