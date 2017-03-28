package pman.ui;

import tannus.io.*;

import electron.Tools.*;
import foundation.*;

import tannus.chrome.FileSystem;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;

import Std.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class ConfirmBox extends Pane {
    /* Constructor Function */
    public function new():Void {
        super();
        resultEvent = new Signal();
        build();
    }

/* === Instance Methods === */

    /**
      * build the shit
      */
    override function populate():Void {
        title = new Heading( 4 );
        append( title );
        btnRow = new FlexRow([6, 6]);
        append( btnRow );
        cancelBtn = new Button('Cancel');
        confirmBtn = new Button('Confirm');
        btnRow.pane(0).append( cancelBtn );
        btnRow.pane(1).append( confirmBtn );

        cancelBtn.expand( true );
        confirmBtn.expand( true );

        addClass( 'confirm' );

        inline function submit(value : Bool):Void {
            resultEvent.call( value );
            close();
        }

        cancelBtn.on('click', function(e) {
            submit( false );
        });
        confirmBtn.on('click', function(e) {
            submit( true );
        });

        cancelBtn.el.focus();
    }

    /**
      * wait for input
      */
    public function prompt(msg:String, callback:Bool->Void):Void {
        message = msg;
        resultEvent.once( callback );
    }

    /**
      * open [this]
      */
    public function open():Void {
        if (!childOf('body')) {
            appendTo( 'body' );
            defer( __center );
        }
    }

    /**
      * close [this]
      */
    public function close():Void {
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

    public var message(get, set):String;
    private inline function get_message() return title.text;
    private inline function set_message(v) return (title.text = v);

    public var cancelLabel(get, set):String;
    private inline function get_cancelLabel() return cancelBtn.text;
    private inline function set_cancelLabel(v) return (cancelBtn.text = v);

    public var confirmLabel(get, set):String;
    private inline function get_confirmLabel() return confirmBtn.text;
    private inline function set_confirmLabel(v) return (confirmBtn.text = v);

/* === Instance Fields === */

    public var title : Heading;
    public var btnRow : FlexRow;
    public var cancelBtn : Button;
    public var confirmBtn : Button;

    public var resultEvent : Signal<Bool>;
}
