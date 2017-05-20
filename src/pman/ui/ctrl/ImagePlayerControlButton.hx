package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import vex.core.Path as VPath;

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
using tannus.ds.AnonTools;

class ImagePlayerControlButton extends IconicPlayerControlButton<Image> {
	override function drawIcon(icon:Null<Image>, c:Ctx):Void {
		if (icon == null)
			return ;
		c.drawComponent(icon, 0, 0, icon.width, icon.height, x, y, w, h);
	}

    /**
      * make an icon 'hollow' (just outlined)
      */
	private function _outline(color:Color, width:Float, ?f:VPath->Void):VPath->Void {
	    return function(p : VPath):Void {
	        p.style.fill = 'transparent';
	        p.style.strokeWidth = width;
	        p.style.stroke = color;
	        if (f != null)
	            f( p );
	    };
	}

	/**
	  * fill an icon with the given Color
	  */
	private function _fill(color:Color, opacity:Float=1.0, ?f:VPath->Void):VPath->Void {
	    return function(p : VPath):Void {
	        p.style.with({
	            _.fill = color;
	            _.fillOpacity = opacity;
	            if (f != null)
	                f( p );
	        });
	    };
	}

    /**
      * default 'enabled' styling
      */
	private function _enabled(?f : VPath->Void):VPath->Void {
	    return _fill(player.theme.secondary, null, f);
	}

    /**
      * default 'disabled' styling
      */
	private function _disabled(?f : VPath->Void):VPath->Void {
	    return _outline(new Color(255, 255, 255), 0.5, f);
	}
}
