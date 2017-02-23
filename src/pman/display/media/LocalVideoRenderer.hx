package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.display.Video;

import pman.core.*;
import pman.media.*;

import foundation.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class LocalVideoRenderer extends LocalMediaObjectRenderer<Video> {
	/* Constructor Function */
	public function new(m:Media, mc:MediaController):Void {
		super(m, mc);

		//canvas = new Canvas();
		vr = new Rectangle();
	}

/* === Instance Methods === */

	/**
	  * render [this] View
	  */
	override function render(stage:Stage, c:Ctx):Void {
		c.drawComponent(v, 0, 0, v.width, v.height, vr.x, vr.y, vr.width, vr.height);
		//c.drawComponent(v, 0, 0, v.width, v.height, x, y, w, h);
	}

	/**
	  * update [this] View
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		if (pv != null) {
			var videoSize:Rectangle = ovr;
			var viewport:Rectangle = pv.rect.clone();
			var scale:Float = marScale(ovr, pv.rect);

			// scale the video-rect
			vr.width = (videoSize.width * scale);
			vr.height = (videoSize.height * scale);

			// center the video-rect
			vr.centerX = viewport.centerX;
			vr.centerY = viewport.centerY;
		}
	}

	/**
	  * scale to the maximum size that will fit in the viewport AND maintain aspect ratio
	  */
	private function marScale(src:Rectangle, dest:Rectangle):Float {
		return min((dest.width / src.width), (dest.height / src.height));
	}

	/**
	  * when [this] gets attached to the view
	  */
	override function onAttached(pv : PlayerView):Void {
		super.onAttached( pv );
		
		if (this.pv == null) {
			this.pv = pv;
		}
	}

	/**
	  * when [this] gets detached from the view
	  */
	override function onDetached(pv : PlayerView):Void {
		super.onDetached( pv );
	}

/* === Computed Instance Fields === */

	public var v(get, never):Video;
	private inline function get_v():Video return this.m;

	private var ovr(get, never):Rectangle;
	private inline function get_ovr():Rectangle return new Rectangle(0, 0, v.width, v.height);

/* === Instance Fields === */

	private var canvas : Canvas;
	private var vr : Rectangle;

	private var pv : Null<PlayerView> = null;
}
