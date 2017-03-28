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

class PlayerControlButton extends Ent {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super();

		controls = c;
		btnFloat = Left;
		tb = new TextBox();
		tb.color = (player.theme.secondary.darken( 35 ));
		tb.fontFamily = 'Ubuntu';
		tb.fontSize = 11;
		tb.fontSizeUnit = 'px';
		tb.bold = true;
		//tb.color = new Color(255, 255, 255);
		//tb.backgroundColor = new Color(255, 0, 0);
		//tb.padding = 1;
		label = null;
		enabled = true;

		__bindEvents();
	}

/* === Instance Methods === */

	/**
	  * Update [this]
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		if ( !enabled ) {
			hide();
		}
		else {
			show();
		}

	    var mp = stage.getMousePosition();
	    hovered = (mp != null && containsPoint( mp ));
	}

	/**
	  * draw [this]
	  */
	override function render(stage:Stage, c:Ctx):Void {
		super.render(stage, c);

		if (label != null) {
			__drawLabel(stage, c);
		}
	}

	/**
	  * update [this] object's geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
		h = 35;
		w = h;
	}

	/**
	  * draw [this] button's badge
	  */
	private function __drawLabel(stage:Stage, c:Ctx):Void {
		if (tb.text != label) {
			tb.text = label;
		}

		var lx:Float = (x + w - (tb.width * 0.60));
		var ly:Float = ((y + h) - tb.height);
		//var badgeRect:Rectangle = new Rectangle(lx, ly, tb.width, tb.height);

		//c.beginPath();
		//c.fillStyle = 'red';
		//c.drawRoundRect(badgeRect, 0.5);
		//c.closePath();
		//c.fill();

		c.drawComponent(tb, 0, 0, tb.width, tb.height, lx, ly, tb.width, tb.height);
	}

/* === Event Methods === */

	/**
	  * handle click events
	  */
	public function click(event : MouseEvent):Void {
		null;
	}

	/**
	  * handle right-click events
	  */
	public function rightClick(event : MouseEvent):Void {
		null;
	}

	/**
	  * bind Event listeners
	  */
	private function __bindEvents():Void {
		on('click', click);
		on('contextmenu', rightClick);
	}

/* === Computed Instance Fields === */

	public var player(get, never):Player;
	private inline function get_player():Player return controls.playerView.player;

/* === Instance Fields === */

	public var controls : PlayerControlsView;
	public var btnFloat : BtnFloat;
	public var label : Null<String>;
	public var enabled : Bool;
	public var hovered : Bool = false;

	private var tb : TextBox;
}

@:enum
abstract BtnFloat (Bool) from Bool to Bool {
	var Left = false;
	var Right = true;
}
