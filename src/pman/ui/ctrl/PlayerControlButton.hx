package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
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
import pman.Globals.*;

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
		tt = new CanvasTooltip();
		//c.addSibling( tt );
		//tt.hide();
		name = null;
		label = null;
		tooltip = null;
		enabled = true;

		__bindEvents();
	}

/* === Instance Methods === */

	/**
	  * Update [this]
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

        // toggle [this] button's visibility by the value of [enabled]
        (enabled?show:hide)();

        // update the value of [hovered]
        var _ph:Bool = hovered;
	    var mp:Null<Point<Float>> = stage.getMousePosition();
	    hovered = (mp != null && containsPoint( mp ));

	    switch ([_ph, hovered]) {
	        // mouse cursor has entered [this] button's content rectangle
            case [false, true]:
                hoverStartTime = now();
                hoverIntended = false;
                tt.hide();

            // mouse cursor has left [this] button's content rectangle
            case [true, false]:
                hoverStartTime = 0.0;
                hoverIntended = false;
                tt.hide();

            // mouse cursor has remained within the bounds of [this] button's content rectangle
            case [true, true]:
                // mouse cursor has been in the content rectangle for at least [hoverIntentDelay] milliseconds
                // and the 'hoverintent' event has not yet been fired
                if ((now() - hoverStartTime) >= hoverIntentDelay && !hoverIntended) {
                    dispatch('hoverintent', mp);
                    hoverIntended = true;
                    tt.show();
                }

            // any other case
            default:
                null;
	    }

        if (tooltip != null && tooltip.trim().length == 0) {
            tooltip = null;
        }

	    if (hoverIntended && tooltip != null) {
	        tt.text = tooltip;
	        tt.position.spacing = 10.0;
	        tt.position.from.x = centerX;
	        tt.position.from.y = y;
	        tt.position.from.width = rect.width;
	        tt.position.from.height = rect.height;
			tt.update( stage );
	    }
	}

	/**
	  * draw [this]
	  */
	override function render(stage:Stage, c:Ctx):Void {
		super.render(stage, c);

		if (label != null) {
			__drawLabel(stage, c);
		}

        if (hoverIntended && tooltip != null) {
            tt.render(stage, c);
        }
	}

	/**
	  * update [this] object's geometry
	  */
	override function calculateGeometry(r : Rect<Float>):Void {
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
	public var name : Null<String>;
	public var label : Null<String>;
	public var tooltip : Null<String>;
	public var enabled : Bool;
	public var hovered : Bool = false;
	public var hoverIntended : Bool = false;

	private var tb : TextBox;
	private var tt : CanvasTooltip;

    // 0.8sec
	private var hoverIntentDelay : Float = 800;
	private var hoverStartTime : Float = 0.0;
}

@:enum
abstract BtnFloat (Bool) from Bool to Bool {
	var Left = false;
	var Right = true;
}
