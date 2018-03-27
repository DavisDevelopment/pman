package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.media.*;

import foundation.Tools.defer;
import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;

/**
  * base-class for the rendering systems of each Media implementation
  */
class MediaRenderer extends Ent {
	/* Constructor Function */
	public function new(media : Media):Void {
		super();

		this.media = media;
		this.components = new Array();
	}

/* === PMan Methods === */

	/**
	  * invoked when [this] view has just been attached to the main view
	  */
	public function onAttached(pv : PlayerView):Void {
		//trace(Type.getClassName(Type.getClass( this )) + ' attached to the main view');
		var tasks:Array<VoidAsync> = new Array();
		for (c in components) {
		    tasks.push(function(next) {
		        c.attached(next.void());
		    });
		}
		tasks.series(function(?error) {
		    if (error != null)
		        report( error );
		});
	}

	/**
	  * invoked when [this] view has just been detached from the main view
	  */
	public function onDetached(pv : PlayerView):Void {
		//trace(Type.getClassName(Type.getClass( this )) + ' detached from the main view');
        var tasks:Array<VoidAsync> = new Array();
		for (c in components) {
		    tasks.push(function(next) {
		        c.detached(next.void());
		    });
		}
		tasks.series(function(?error) {
		    if (error != null)
		        report( error );
		});
	}

	/**
	  * invoked when the Player page closes
	  */
	public function onClose(p : Player):Void {
	    //
	}

	/**
	  * invoked when the Player page reopens
	  */
	public function onReopen(p : Player):Void {
	    //
	}

	/**
	  * unlink and deallocate [this]'s memory
	  */
	public function dispose():Void {
		delete();

		for (c in components) {
		    _deleteComponent( c );
		}
	}

    /**
      * attach a MediaRendererComponent to [this]
      */
	public function _addComponent(c: MediaRendererComponent):Void {
	    components.push( c );
	}

    /**
      * remove a MediaRendererComponent from [this]
      */
	public function _deleteComponent(c: MediaRendererComponent):Void {
	    components.remove( c );
	    c.renderer = null;
	}

/* === Gryffin Methods === */

	/**
	  * perform per-frame logic for [this] view
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		for (c in components) {
		    c.update( stage );
		}
	}
	
	/**
	  * render [media]
	  */
	override function render(stage:Stage, c:Ctx):Void {
		super.render(stage, c);

		for (comp in components) {
		    comp.render(stage, c);
		}
	}

	/**
	  * calculate [this] view's geometry
	  */
	override function calculateGeometry(viewport : Rect<Float>):Void {
		rect.pull( viewport );
	}

/* === Instance Fields === */

	public var media : Media;
	public var mediaController : MediaController;

	private var components: Array<MediaRendererComponent>;
}
