package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class IconicPlayerControlButton<Icon> extends PlayerControlButton {
	/* Constructor Function */
	public function new(p : PlayerControlsView):Void {
		super( p );

		_il = new Array();
		iconSize = 64;
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	override function init(stage : Stage):Void {
		super.init( stage );
		initIcon();
	}

	/**
	  * initialize Icon-related data
	  */
	public function initIcon():Void {
		null;
	}

    /**
      * update [this]
      */
	override function update(stage : Stage):Void {
	    super.update( stage );
	}

	/**
	  * draw [this]
	  */
	override function render(stage:Stage, c:Ctx):Void {
	    if (glow && hovered) {
	        c.save();
	        c.shadowColor = getGlowColor();
	        c.shadowBlur = 5;
	        drawIcon(getIcon(), c);
	        c.restore();
	    }
        else {
            drawIcon(getIcon(), c);
        }
		super.render(stage, c);
	}

	/**
	  * get the object that will be drawn as the icon
	  */
	public function getIcon():Null<Icon> {
		return _il[0];
	}

	/**
	  * actually draw the Icon to the canvas
	  */
	public function drawIcon(icon:Null<Icon>, c:Ctx):Void {
		null;
	}

	/**
	  * get the glow color
	  */
	public function getGlowColor():String {
	    return 'white';
	}

/* === Instance Fields === */

    public var glow : Bool = true;

	private var _il : Array<Icon>;
	private var iconSize : Int;
}
