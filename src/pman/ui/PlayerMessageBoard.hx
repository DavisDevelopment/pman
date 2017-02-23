package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.graphics.Color;
import tannus.css.Value;
import tannus.css.vals.Lexer;

import haxe.extern.EitherType;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.Tools.*;

import pman.core.*;
import pman.display.*;

using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class PlayerMessageBoard extends Ent {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();

		player = p;
		box = new TextBox();
		box.padding = 7;
		box.fontSize = 14;
		box.fontFamily = 'Ubuntu';
		box.color = new Color(255, 255, 255);
		currentMessage = null;
	}

/* === Instance Methods === */

	/**
	  * Update [this]
	  */
	override public function update(stage : Stage):Void {
		super.update( stage );

		if (currentMessage != null) {
			// Message duration
			var dur:Float = (currentMessage.duration != null ? currentMessage.duration : 6500);
			if ((now - currentMessage.startTime) > dur) {
				currentMessage = null;
			}
			else {
				syncBox();

				w = box.width;
				h = box.height;
				x = (pview.x + 12);
				y = (pview.y + 12);
			}
		}
	}

	/**
	  * Render current message
	  */
	override public function render(stage:Stage, c:Ctx):Void {
		super.render(stage, c);

		if (currentMessage != null) {
			// draw the background
			c.beginPath();
			c.fillStyle = player.theme.primary;
			c.drawRoundRect(rect, 5);
			c.closePath();
			c.fill();

			// draw the text
			c.drawComponent(box, 0, 0, box.width, box.height, x, y, w, h);
		}
	}

	private function syncBox():Void {
		var m = currentMessage;
		// set defaults
		box.fontSize = 14;
		box.fontFamily = 'Ubuntu';
		box.color = new Color(255, 255, 255);

		// start syncing values
		box.text = m.text;
		if (m.color != null) {
			box.color = m.color;
		}
		if (m.backgroundColor != null) {
			box.backgroundColor = m.backgroundColor;
		}
		if (m.fontSize != null) {
			box.fontSize = m.fontSize.size;
			box.fontSizeUnit = m.fontSize.unit;
		}
	}

	/**
	  * post a message to [this]
	  */
	public function post(message : EitherType<String, MessageOptions>):Void {
		var options:MessageOptions;
		if (Std.is(message, String)) {
			options = {
				text: cast(message, String)
			};
		}
		else {
			options = cast message;
		}

		currentMessage = new Message( options );
		currentMessage.start();
	}

/* === Computed Instance Fields === */

	public var pview(get, never):PlayerView;
	private inline function get_pview():PlayerView return player.view;

/* === Instance Fields === */

	public var player : Player;

	public var currentMessage : Null<Message>;
	
	private var box : TextBox;
	//private var msgStartTime:Float;
}

private class Message {
	/* Constructor Function */
	public function new(options : MessageOptions):Void {
		text = options.text;
		duration = options.duration;
		color = options.color;
		backgroundColor = options.backgroundColor;
		fontSize = null;

		__pull( options );
	}

	private function __pull(o : MessageOptions):Void {
		if (o.fontSize != null) {
			var value = Lexer.parseString( o.fontSize )[0];
			if (value != null) {
				switch ( value ) {
					case Value.VNumber(num, unit):
						if (unit == null) unit = 'pt';
						fontSize = {
							size: num,
							unit: unit
						};

					default:
						null;
				}
			}
		}
	}

	public inline function start():Void {
		startTime = now;
	}

	public var text : String;
	public var duration : Null<Float>;
	public var color : Null<Color>;
	public var backgroundColor : Null<Color>;
	public var fontSize : Null<FontSize>;

	public var startTime : Float;
}

typedef MessageOptions = {
	text : String,
	?duration : Float,
	?color : Color,
	?backgroundColor : Color,
	?fontSize : String
};

private typedef FontSize = {
	size : Float,
	unit : String
};
