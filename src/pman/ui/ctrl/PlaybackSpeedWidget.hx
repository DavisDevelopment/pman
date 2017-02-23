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

class PlaybackSpeedWidget extends Ent {
	/* Constructor Function */
	public function new(c:PlayerControlsView, b:PlaybackSpeedButton):Void {
		super();

		controls = c;
		button = b;
		options = new Array();

		hide();
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	override function init(stage : Stage):Void {
		super.init( stage );

		buildOptions();
	}

	/**
	  * update [this]
	  */
	override function update(stage : Stage):Void {
		super.update( stage );
	}

	/**
	  * render [this]
	  */
	@:access( pman.ui.PlayerControlsView )
	override function render(stage:Stage, c:Ctx):Void {
		var bg = controls.getBackgroundColor();
		c.fillStyle = bg.toString();
		c.beginPath();
		c.drawRoundRect(rect, 4.0);
		c.closePath();
		c.fill();

		super.render(stage, c);
	}

	/**
	  * calculate [this]'s geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
		w = 100;
		centerX = button.centerX;
		h = calculateHeight();
		y = (controls.y - h - 7);

		super.calculateGeometry( r );
		positionOptions();
	}

	/**
	  * calculate the height of [this]
	  */
	private function calculateHeight():Float {
		var result:Float = margin;
		for (o in options) {
			result += (o.h + margin);
		}
		return result;
	}

	/**
	  * position all option buttons
	  */
	private function positionOptions():Void {
		var oy:Float = (y + margin);
		for (o in options) {
			o.y = oy;
			oy += o.h;
			oy += margin;
		}
		oy += margin;
	}

	/**
	  * build all options
	  */
	private function buildOptions():Void {
		var all:Array<NamedSpeed> = [Slow, Normal, Fast, VeryFast];
		for (value in all) {
			var o = option( value );
			addOption( o );
		}
	}

	/**
	  * add an Option
	  */
	private inline function addOption(o : PlaybackSpeedOption):Void {
		addChild( o );
		options.push( o );
	}

	private inline function option(value : NamedSpeed):PlaybackSpeedOption {
		return new PlaybackSpeedOption(controls, button, this, value);
	}

/* === Instance Fields === */

	public var controls : PlayerControlsView;
	public var button : PlaybackSpeedButton;

	public var options : Array<PlaybackSpeedOption>;

	private var margin : Float = 4.0;
	//private var totalWidth : Float;
	//private var totalHeight : Float;
}

@:enum
abstract NamedSpeed (Float) from Float to Float {
	var Slow = 0.75;
	var Normal = 1.00;
	var Fast = 1.25;
	var VeryFast = 1.75;

	public static inline function isNamedSpeed(n : Float):Bool {
		return [Slow, Normal, Fast, VeryFast].has( n );
	}

	public function getName():String {
		return switch ( this ) {
			case Slow: 'Slow';
			case Normal: 'Normal';
			case Fast: 'Fast';
			case VeryFast: 'Very Fast';
			default: Std.string( this );
		};
	}

	public inline function getValue():Float {
		return this;
	}
}
