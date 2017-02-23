package crayon;

import foundation.*;
import tannus.html.Element;
import tannus.html.Win;
import tannus.ds.*;
import tannus.io.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.macro.MacroTools;

class Body extends Widget {
	/* Constructor Function */
	public function new(app : Application):Void {
		super();

		el = 'body';
		pageChange = new Signal();
		currentPage = null;
		application = app;

		activate();
	}

/* === Instance Methods === */

	/**
	  * Open a Page
	  */
	public function open(page : Page):Void {
		if (currentPage != null) {
			currentPage.close();
			page.previousPage = currentPage;
		}

		trace('body activated: ${ this._active }');

		currentPage = page;
		append( page );
		currentPage = page;
		(page.opened ? page.reopen : page.open)( this );

		/*
		if ( !page._active ) {
			activate();
		}
		*/
	}

/* === Computed Instance Fields === */

	/* the title of [this] Body */
	public var title(get, set):String;
	private inline function get_title():String return application.title;
	private inline function set_title(v : String):String return (application.title = v);

	/* the current active Page on [this] Body */
	public var currentPage(default, set): Null<Page>;
	private function set_currentPage(newPage : Null<Page>):Null<Page> {
		var previous = currentPage;
		var current  = (currentPage = newPage);
		var delta = new Delta(current, previous);
		pageChange.call( delta );
		return current;
	}

/* === Instance Fields  === */

	public var application : Application;
	public var pageChange : Signal<Delta<Maybe<Page>>>;
}
