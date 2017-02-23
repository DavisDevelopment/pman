package pman.ui.pl;

import tannus.ds.*;
import tannus.io.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;

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
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using Slambda;

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
		/*
		inputRow = new FlexRow([10, 2]);
		append( inputRow );
		*/
		searchInput = new TextInput();
		//inputRow.pane( 0 ).append( searchInput );
		append( searchInput );
		/*
		submitButton = new Button( 'go' );
		submitButton.small( true );
		submitButton.expand( true );
		inputRow.pane( 1 ).append( submitButton );
		*/

		__events();

		css.write({
			'width': '98%',
			'margin-left': 'auto',
			'margin-right': 'auto'
		});
	}

	/**
	  * handle keyup events
	  */
	private function onkeyup(event : KeyboardEvent):Void {
		switch ( event.key ) {
			case Enter:
				submit();

			default:
				null;
		}
	}

	/**
	  * the search has been 'submit'ed
	  */
	private function submit():Void {
		var d:SearchData = getData();
		
		if (d.search != null) {
			//TODO parse the search term and perform the search
		}
		else {
			//TODO reset the view to displaying the playlist
		}
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

		return {
			search: inputText
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
		//submitButton.on('click', function(event : MouseEvent) {
			//submit();
		//});
	}

/* === Instance Fields === */

	public var player : Player;
	public var playlistView : PlaylistView;

	public var inputRow : FlexRow;
	public var searchInput : TextInput;
	//public var submitButton : Button;
}

/**
  * typedef for the object that holds the form data
  */
typedef SearchData = {
	?search : String
};
