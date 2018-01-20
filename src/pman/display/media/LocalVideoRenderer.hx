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
import pman.ui.VideoUnderlay;
import pman.display.VideoFilter;
import pman.edb.*;

import foundation.Tools.defer;
import Std.*;
import tannus.math.TMath.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.graphics.ColorTools;

/*
   Renderer for video media
*/
class LocalVideoRenderer extends LocalMediaObjectRenderer<Video> {
	/* Constructor Function */
	public function new(m:Media, mc:MediaController):Void {
		super(m, mc);

		canvas = new Canvas();
		vr = new Rectangle();
		filter = null;
	}

/* === Instance Methods === */

	/**
	  * render [this] View
	  */
	override function render(stage:Stage, c:Ctx):Void {
	    if (underlay == null) {
	        if (!filterRaw && filter != null) {
                c.filter = filter;
            }
            _paint();
            c.drawComponent(canvas, 0, 0, canvas.width, canvas.height, vr.x, vr.y, vr.width, vr.height);
        }
        else {
            if (underlay != null) {
                var cc = underlay.css;
                cc.set('filter', (filter == null ? 'none' : filter.toString()));
            }
        }

        if (visualizer != null) {
            visualizer.render(stage, c);
        }
	}

	/**
	  * paint [this] to the canvas
	  */
	private function _paint():Void {
	    if (canvas.width != v.width || canvas.height != v.height) {
	        canvas.resize(v.width, v.height);
	    }
	    var cc = canvas.context;
	    cc.drawComponent(v, 0, 0, v.width, v.height, 0, 0, v.width, v.height);
	    if (filterRaw && filter != null) {
            try {
                var pixels = cc.getPixels(0, 0, canvas.width, canvas.height);
                filter.applyToPixels( pixels );
                pixels.write(cc, 0, 0, 0, 0, pixels.width, pixels.height);
                //pixels.save();
            }
            catch (error : Dynamic) {
                trace( error );
            }
        }
	}

	/**
	  * update [this] View
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		if (pv != null) {
			var videoSize:Rectangle = ovr;
			var viewport:Rectangle = pv.rect.clone();
			var scale:Float = (marScale(ovr, pv.rect) * pv.player.scale);

			// scale the video-rect
			vr.width = (videoSize.width * scale);
			vr.height = (videoSize.height * scale);

			// center the video-rect
			vr.centerX = viewport.centerX;
			vr.centerY = viewport.centerY;

			if (underlay != null) {
			    underlay.setRect( vr );
			}
		}
		if (visualizer != null) {
		    visualizer.update( stage );
		}

        var vo = player.viewOptions;
        this.filter = vo.videoFilter;
        this.filterRaw = vo.videoFilterRaw;
        this.directRender = (filterRaw || preferences.directRender);
        //this.directRender = true;

        if ( directRender ) {
            if (underlay == null) {
                underlay = new VideoUnderlay( v );
                underlay.appendTo('body');
            }
        }
        else {
            if (underlay != null) {
                underlay.detach();
                underlay = null;
            }
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
			vr = pv.mediaRect;
		}

		if ( prefs.directRender ) {
            underlay = new VideoUnderlay( v );
            underlay.appendTo( 'body' );
        }
	}

	/**
	  * when [this] gets detached from the view
	  */
	override function onDetached(pv : PlayerView):Void {
		super.onDetached( pv );
		detachVisualizer(function() {
            if (underlay != null)
                underlay.destroy();
        });
	}

	/**
	  * when the Player gets closed
	  */
	override function onClose(p : Player):Void {
	    if (underlay != null) {
	        underlay.detach();
	        underlay = null;
	    }
	    detachVisualizer(function() {
	        return ;
	    });
	}

    /**
      * when the player gets reopened
      */
	override function onReopen(p : Player):Void {
		if ( prefs.directRender ) {
            underlay = new VideoUnderlay( v );
            underlay.appendTo( 'body' );
        }
        else if (underlay != null) {
            underlay.detach();
            underlay = null;
        }
	}

/* === Computed Instance Fields === */

	public var v(get, never):Video;
	private inline function get_v():Video return this.m;

	private var ovr(get, never):Rectangle;
	private inline function get_ovr():Rectangle return new Rectangle(0, 0, v.width, v.height);

    public var prefs(get, never):Preferences;
    private inline function get_prefs() return BPlayerMain.instance.db.preferences;

/* === Instance Fields === */

	private var canvas : Canvas;
	private var vr : Rectangle;

	private var pv : Null<PlayerView> = null;
	private var underlay : Null<VideoUnderlay> = null;
	private var filter : Null<VideoFilter> = null;
	private var directRender : Bool = true;
	private var filterRaw : Bool = false;
}
