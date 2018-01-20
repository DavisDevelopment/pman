package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.sys.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.bg.media.*;
import pman.media.*;

import edis.Globals.*;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class LocalImageRenderer extends MediaRenderer {
    /* Constructor Function */
    public function new(m:Media, c:MediaController):Void {
        super( m );

        mediaController = c;
        if ((mediaController is LocalImageMediaDriver)) {
            var imd = cast(mediaController, LocalImageMediaDriver);
            this.i = imd.i;
        }
        else {
            throw 'WTF';
        }
        vr = new Rectangle();
    }

/* === Instance Methods === */

    override function render(stage:Stage, c:Ctx):Void {
        c.drawComponent(i, 0, 0, i.width, i.height, vr.x, vr.y, vr.width, vr.height);
    }

    override function update(stage: Stage):Void {
        super.update( stage );

        var imgSize = new Rectangle(0, 0, i.width, i.height);
        var viewport = pv.rect.clone();
        var scale:Float = (marScale(imgSize, pv.rect) * pv.player.scale);

        vr.width = (imgSize.width * scale);
        vr.height = (imgSize.height * scale);
        vr.centerX = viewport.centerX;
        vr.centerY = viewport.centerY;
    }

    /**
	  * scale to the maximum size that will fit in the viewport AND maintain aspect ratio
	  */
	private inline function marScale(src:Rectangle, dest:Rectangle):Float {
		return min((dest.width / src.width), (dest.height / src.height));
	}

    override function dispose():Void {
        super.dispose();

        i = null;
    }

    override function onAttached(pv: PlayerView):Void {
        super.onAttached( pv );

        this.pv = pv;
    }

    override function onDetached(pv: PlayerView):Void {
        super.onDetached( pv );
        pv = null;
    }

/* === Instance Fields === */

    public var i: Null<Image>;
    public var vr: Rectangle;

	private var pv : Null<PlayerView> = null;
}
