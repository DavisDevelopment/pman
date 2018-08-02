package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.*;
import tannus.events.Key;
import tannus.html.Element;

import foundation.*;

import pman.core.*;

import Std.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.FunctionTools;

class MultiButtonSelectBox extends Pane {
    /* Constructor Function */
    public function new():Void {
        super();
        resultEvent = new Signal();
        buttons = new Array();

        build();
    }

/* === Instance Methods === */

    /**
      * build the shit
      */
    override function populate():Void {
        modal = new Modal();
        title = new Heading( 4 );
        append( title );
        btnRow = new Pane();
        btnRow.addClass('row');
        append( btnRow );

        addClass('multi-btn-select');
    }

    public function addBtn(spec: {label:String, ?value:String, ?select:String->Void}) {
        if (spec.value == null)
            spec.value = spec.label;

        var btn:Button = new Button(spec.label);
        btn.expand(true);
        btn.meta('pm:value', spec.value);

        if (spec.select == null) 
            spec.select = (x -> trace(x));
        spec.select = spec.select.once();

        btn.on('click', function(event) {
            var v:String = btn.meta('pm:value');
            
            _select_(v, spec.select);
        });

        buttons.push( btn );
        btnRow.append( btn );
    }

    public function button(txt:String, value:String, ?handler:String->Void) {
        addBtn({
            label: txt,
            value: value,
            select: handler
        });
    }

    function _select_(value:String, ?handler:String->Void) {
        if (handler != null)
            handler( value );
        resultEvent.call( value );
    }

    /**
      * wait for input
      */
    public function prompt(msg:String, callback:String->Void):Void {
        message = msg;
        resultEvent.once(callback.wrap(function(_, value) {
            _( value );
            close();
        }));
    }

    /**
      * open [this]
      */
    public function open():Void {
        if (!childOf('body')) {
            appendTo( 'body' );
            modal.open();
            defer( __center );
        }
    }

    /**
      * close [this]
      */
    public function close():Void {
        modal.close();
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

/* === Instance Fields === */

    public var title : Heading;
    public var btnRow : Pane;
    public var modal : Modal;
    var buttons:Array<Button>;

    public var resultEvent : Signal<String>;
}
