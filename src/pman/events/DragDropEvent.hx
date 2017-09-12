package pman.events;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.html.fs.WebFile;

import js.html.DragEvent as NativeDragEvent;
import js.jquery.Event as JqEvent;

import pman.ds.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class DragDropEvent extends Event {
	/* Constructor Function */
	public function new(nativeEvent : NativeDragEvent):Void {
		super( nativeEvent.type );

		e = nativeEvent;
		
		onDefaultPrevented.once( e.preventDefault );
		onPropogationStopped.once( e.stopImmediatePropagation );
		onCancelled.once(function() {
			preventDefault();
			stopPropogation();
		});
	}

/* === Instance Methods === */

    public function globalPosition():Point {
        return new Point(e.pageX, e.pageY);
    }

/* === Computed Instance Fields === */

	public var dataTransfer(get, never):DataTransfer;
	private inline function get_dataTransfer():DataTransfer return new DataTransfer(untyped e.dataTransfer);

/* === Instance Fields === */

	private var e : NativeDragEvent;

/* === Class Methods === */

	/**
	  * create a DragDrop event from a NativeDragEvent
	  */
	public static function fromJsEvent(event : NativeDragEvent):DragDropEvent {
		return new DragDropEvent( event );
	}
	public static function fromJqEvent(event : JqEvent):DragDropEvent {
		var orig = Reflect.getProperty(event, 'originalEvent');
		if (orig != null && Std.is(orig, NativeDragEvent)) {
			return fromJsEvent(cast orig);
		}
		else {
			throw 'Error: Invalid event';
		}
	}
}
