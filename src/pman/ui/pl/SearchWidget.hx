package pman.ui.pl;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;
import tannus.events.Key;
import tannus.sys.*;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.media.*;
import pman.search.TrackSearchEngine;

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
		optionsRow.css.set('display', 'none');
		append( optionsRow );

		srcSelect = new Select();
		srcSelect.option('queue', 'q');
		srcSelect.option('all media', 'all');
		optionsRow.pane( 1 ).append( srcSelect );

		__events();

		css.write({
			'width': '98%',
			'margin-left': 'auto',
			'margin-right': 'auto'
		});

		update(); } 
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
				submit();
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
	private function submit():Void {
	    // get search data
		var d:SearchData = getData();
		// if a search term was provided
		if (d.search != null) {
		    // create a search engine
			var engine = new TrackSearchEngine();
			// enable engine's strictness
			engine.strictness = 1;
			// set engine's context
			engine.setContext(player.session.playlist.getRootPlaylist().toArray());
			// set engine's search term
			engine.setSearch( d.search );
			// calculate search results
			var matches = engine.getMatches();
			// sort the results by relevancy
			matches.sort(function(x, y) {
				return -Reflect.compare(x.score, y.score);
			});
			// build playlist from results
			var resultList:Playlist = new Playlist(matches.map.fn( _.item ));
			resultList.parent = player.session.playlist.getRootPlaylist();
			player.session.setPlaylist( resultList );
		}
		// if search term was empty
		else {
		    // reset track list to root
		    var pl = player.session.playlist;
		    player.session.setPlaylist(pl.getRootPlaylist());
		}

        // update display
		defer( update );
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
		clear.el.on('click', function(e) {
		    clearSearch();
		});
		//submitButton.on('click', function(event : MouseEvent) {
			//submit();
		//});
	}

	public function clearSearch():Void {
	    searchInput.setValue( null );
	    submit();
	}

/* === Instance Fields === */

	public var player : Player;
	public var playlistView : PlaylistView;

	public var inputRow : Pane;
	public var searchInput : TextInput;
	public var searchButton : Element;
	public var optionsRow : FlexRow;
	public var srcSelect : Select<String>;
	public var clear : foundation.Image;
	//public var submitButton : Button;
}

/**
  * typedef for the object that holds the form data
  */
typedef SearchData = {
	?search : String
};
