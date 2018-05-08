package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import edis.core.Prerequisites as Reqs;

import pman.core.*;
import pman.media.*;

import foundation.Tools.defer;
import Std.*;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;

/**
  * base-class for the rendering systems of each Media implementation
  */
class MediaRenderer extends Ent {
	/* Constructor Function */
	public function new(media : Media):Void {
		super();

		this.media = media;
		this.prereqs = new Reqs();
		this.components = new Array();
		this.attachedEvent = new VoidSignal();
		this.detachedEvent = new VoidSignal();

		attachedEvent.once(function() {
		    prereqs.meet(function(?error) {
		        if (error != null) {
		            report( error );
		        }
                else {

                    _attached = true;
                }
		    });
		});

		detachedEvent.once(function() {
		    _attached = false;
		});
	}

/* === PMan Methods === */

	/**
	  * invoked when [this] view has just been attached to the main view
	  */
	public function onAttached(pv:PlayerView, done:VoidCb):Void {
		//trace(Type.getClassName(Type.getClass( this )) + ' attached to the main view');
		attachComponents(components.copy(), function(?error) {
		    if (error != null) {
		        report( error );
		        done( error );
            }
            else {
                attachedEvent.fire();
                done();
            }
		});
	}

	/**
	  * invoked when [this] view has just been detached from the main view
	  */
	public function onDetached(pv:PlayerView, done:VoidCb):Void {
		//trace(Type.getClassName(Type.getClass( this )) + ' detached from the main view');
		trace('detaching components..');
        detachComponents(components.copy(), function(?error) {
            if (error != null) {
                report( error );
                done( error );
            }
            else {
                detachedEvent.fire();
                trace('detach complete');
                done();
            }
        });
	}

    /**
      * invoke [f] when [this] becomes attached to the Player's rendering pipeline
      */
	public inline function whenAttached(f: Void->Void):Void {
	    if ( _attached ) {
	        f();
	    }
        else {
            //attachedEvent.once( f );
            prereqs.onmet( f );
        }
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
	public function dispose(done: VoidCb):Void {
	    _deleteComponents(components.copy(), function(?error) {
	        delete();
	        done( error );
	    });

		//delete();

		//for (c in components) {
			//_deleteComponent( c );
		//}
	}

    /**
      * attach a MediaRendererComponent to [this]
      */
	public function _addComponent(c:MediaRendererComponent, done:VoidCb):Void {
        components.push( c );

        if ( _attached ) {
            c.attached( done );
        }
        else {
            done();
        }
	}

    /**
      * add an array of MediaRendererComponent instances to [this]
      */
	public function _addComponents(a:Array<MediaRendererComponent>, done:VoidCb):Void {
		a.map(c -> _addComponent.bind(c, _)).series( done );
	}

    /**
      * remove a MediaRendererComponent from [this]
      */
	public function _deleteComponent(c:MediaRendererComponent, done:VoidCb):Void {
	    components.remove( c );
	    c.renderer = null;

	    if (c.isAttached()) {
	        c.detached( done );
	    }
        else {
            done();
        }
	}

    /**
      * delete a list of MediaRendererComponents
      */
	public function _deleteComponents(a:Array<MediaRendererComponent>, done:VoidCb):Void {
	    return (a.map(function(c) {
	        return _deleteComponent.bind(c, _);
        })).series( done );
	}

    /**
      * detach a list of components
      */
	private function detachComponents(a:Array<MediaRendererComponent>, done:VoidCb):Void {
	    a.map.fn(dcb(_)).series( done );
	}

    /**
      * attach a list of components
      */
	private function attachComponents(a:Array<MediaRendererComponent>, done:VoidCb):Void {
	    a.compact().map.fn(_.attached.bind()).series( done );
	}

    /**
      * require that [task] be completed before [this] is considered ready and attached
      */
	private function _req(task: VoidAsync) {
	    prereqs.vasync( task );
	}

	private function dcb(c:MediaRendererComponent):VoidAsync {
	    var className:String = Type.getClassName(Type.getClass( c ));
	    return c.detached.wrap(function(_, cb:VoidCb) {
	        trace('detaching $className from MediaRenderer..');
	        _(cb.wrap(function(_cb, ?error) {
	            if (error != null) {
	                trace('error occurred detaching $className');
	                _cb( error );
	            }
                else {
                    trace('successfully detached $className');
                    _cb();
                }
	        }));
	    });
	}

/* === Gryffin Methods === */

	/**
	  * perform per-frame logic for [this] view
	  */
	override function update(stage : Stage):Void {
		super.update( stage );

		for (c in components) {
		    if (c.isAttached()) {
                c.update( stage );
            }
		}
	}
	
	/**
	  * render [media]
	  */
	override function render(stage:Stage, c:Ctx):Void {
		super.render(stage, c);

		for (comp in components) {
		    if (comp.isAttached()) {
                comp.render(stage, c);
            }
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

    public var prereqs: Reqs;
	public var components: Array<MediaRendererComponent>;
	public var attachedEvent: VoidSignal;
	public var detachedEvent: VoidSignal;

    private var _attached:Bool = false;
}
