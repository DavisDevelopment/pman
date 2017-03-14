package pman.db;

import tannus.ds.*;
import tannus.io.*;
import tannus.mvc.Requirements;

import electron.Tools.defer;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Model extends EventDispatcher {
    /* Constructor Function */
    public function new():Void {
        super();

        readyreqs = new Requirements();
        _readyEvent = new VoidSignal();
        _readyEvent.once(function() {
            _ready = true;
        });
    }

/* === Instance Methods === */

    /**
      * initialize [this] Model
      */
    public function init(?done : Void->Void):Void {
        if (done != null) {
            onready( done );
        }
        readyreqs.meet(function() {
            sync(function() {
                declareReady();
            });
        });
    }

    /**
      * ensure that [this] Model is ready before invoking [action]
      */
    public inline function onready(action : Void->Void):Void {
        (_ready?defer:_readyEvent.once)( action );
    }

    /**
      * announce that [this] Model is ready
      */
    public inline function declareReady():Void {
        if ( !_ready ) {
            _readyEvent.fire();
        }
    }

	/**
	  * require that Task [t] have completed successfully before [this] Model is considered 'ready'
	  */
	public inline function require(name:String, task:Async):Void {
	    readyreqs.add(name, task);
	}

	/**
	  * persist [this] Model's state
	  */
	public function sync(done : Void->Void):Void {
	    defer( done );
	}

    // get the value of an attribute of [this] Model
    public function getAttribute<T>(name : String):Null<T> {
        return null;
    }
    public inline function get<T>(n:String):Null<T> return getAttribute( n );

    // set the value of an attribute of [this] Model
    public function setAttribute<T>(name:String, value:T):T {
        return value;
    }
    public inline function set<T>(n:String, v:T):T return setAttribute(n, v);

    // check for existence of the given attribute
    public function hasAttribute(name : String):Bool {
        return false;
    }
    public inline function exists(name:String):Bool return hasAttribute( name );

    // delete an attribute
    public function removeAttribute(key : String):Bool {
        return false;
    }
    public inline function remove(key:String):Bool return removeAttribute(key);

    // iterate over attribute names
    public function allAttributes():Array<String> {
        return [];
    }
    public inline function keys():Array<String> return allAttributes();

/* === Instance Fields === */

    public var readyreqs : Requirements;
    private var _readyEvent : VoidSignal;
    private var _ready : Bool = false;
}
