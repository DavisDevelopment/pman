package pman.ui;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.ds.Maybe;
import tannus.events.*;
import tannus.events.Key;

import edis.dom.*;
import edis.dom.components.*;

import pman.core.*;

import Std.*;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class EdisDomComponentPromptBox extends Div {
	/* Constructor Function */
	public function new():Void {
		super();

		addClass( 'pman-prompt' );

        //modal = new Modal();
		input = new TextInput();
		inputRow = new Div();
		inputRow.addClass( 'input-row' );

        //titlRow = new Pane();
        //titlRow.addClass( 'label-row' );
		//titl = new LabelSpan();
		//titlRow.append( titl );
		//append( titlRow );

		inputRow.append( input );
		append( inputRow );

		__listen();
	}

/* === Instance Methods === */

	/**
	  * Open and display [this] PromptBox
	  */
	public function open():Void {
		__init();
		appendTo( 'body' );
		//modal.open();
		__center();
	}

	/**
	  * Close and remove [this] PromptBox
	  */
	public function close():Void {
		destroy();
		//modal.close();
	}

	/**
	  * Shit focus to [this] box
	  */
	public inline function focus():Void {
		//input.focus();
		i.focus();
	}

	/**
	  * set the caret position of [this]
	  */
	public function caret(?index : Int):Int {
	    if (index != null) {
            focus();
            selectRange(index, index);
        }
        return i.selectionEnd;
	}

	/**
	  * Select [this] Input
	  */
	public inline function select():Void {
		i.select();
	}

	/**
	  * Select the given range
	  */
	public inline function selectRange(start:Int, end:Int):Void {
		i.setSelectionRange(start, end);
	}

	/**
	  * Read a single line of input from [this]
	  */
	public function readLine(f : Maybe<String>->Void):Void {
	    var called:Bool = false;
		once('line', function(text) {
		    if ( !called ) {
		        f( text );
		        called = true;
		    }
		});
		once('blank', untyped function() {
		    if (!called) {
                f( null );
                called = true;
            }
		});
	}

	/**
	  * Set the position of [this] Input
	  */
	public function moveTo(x:Float, y:Float):Void {
		css.write({
			left: (x + 'px'),
			top: (y + 'px')
		});
	}

	/**
	  * apply styling to [this] Shit
	  */
	private function __init():Void {
		var c = css;
		c['position'] = 'absolute';
		c['display'] = 'block';
		c['z-index'] = '11111';
		c['top'] = '55px';
		c['width'] = '90%';
	}

	/**
	  * listen to events on [this] shit
	  */
	private function __listen():Void {
		input.on('keydown', function(event : KeyboardEvent) {
			event.stopPropogation();
			keydown( event );
		});

		input.on('keyup', function(event : KeyboardEvent) {
			event.stopPropogation();
			keyup( event );
		});

		//input.on('keyup', keyup);
	}

	/**
	  * Handle a key
	  */
	private function keydown(event : KeyboardEvent):Void {
		switch ( event.key ) {
			case Enter:
				if (!value.trim().empty()) {
					// dispatch('line', value);
					line( value );	
				}
                else {
                    empty();
                }
				close();

			case Esc:
			    event.preventDefault();
			    close();

			default:
				null;
		}
	}

    /**
      *
      */
	private function keyup(event : KeyboardEvent):Void {
	    if (cnu != null && event.key == cnu) {
	        event.cancel();
	        cnu = null;
	    }
	}

	private inline function cancelNextKeyUp(key : Key):Void {
	    cnu = key;
	}

	/**
	  * Handle the entering of a line
	  */
	private function line(l : String):Void {
		dispatch('line', value);
	}

	/**
	  * handles the entering of an empty line
	  */
	private function empty():Void {
	    dispatch('blank', null);
	    destroy();
	}

	/**
	  * Center [this] Box
	  */
	private function __center():Void {
		var mr = el.rectangle;
		var pr = new Element( 'body' ).rectangle;
		var c = css;

		var cx:Float = mr.centerX = pr.centerX;
		c['left'] = '${cx}px';
	}

/* === Computed Instance Fields === */

	/* the value of [this] box */
	public var value(get, set):String;
	private inline function get_value():String return input.getValue();
	private function set_value(v : String):String {
		input.setValue( v );
		return value;
	}

	public var placeholder(get, set):String;
	private inline function get_placeholder():String return input.getPlaceholder();
	private inline function set_placeholder(v : String):String {
	    input.setPlaceholder( v );
	    return v;
	}

	private var i(get, never):js.html.InputElement;
	private inline function get_i() return input.iel;

/* === Instance Fields === */

	public var input : TextInput;
	public var inputRow : Div;

    // cancel next 'keyup' event?
	private var cnu:Null<Key> = null;
}
