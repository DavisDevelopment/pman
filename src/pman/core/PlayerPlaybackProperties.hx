package pman.core;

import tannus.io.Signal;
import tannus.ds.Delta;

import haxe.Serializer;
import haxe.Unserializer;

import electron.Tools.defer;

using tannus.math.TMath;

/**
  persistent playback & view-related application-state information
 **/
class PlayerPlaybackProperties {
	/* Constructor Function */
	public function new(speed:Float, volume:Float, shuffle:Bool, muted:Bool=false, ?repeat:RepeatType, scale:Float=1.0):Void {
	    changed = new Signal();

		this.speed = speed;
		this.volume = volume;
		this.shuffle = shuffle;
		this.muted = muted;
		this.repeat = (repeat != null) ? repeat : RepeatOff;
		this.scale = scale;
	}

/* === Instance Methods === */

    /**
      * create and return a copy of [this]
      */
	public function clone():PlayerPlaybackProperties {
		return new PlayerPlaybackProperties(speed, volume, shuffle, muted, repeat, scale);
	}

	/**
	  * copy data from [src] onto [this]
	  */
	public function rebase(src : PlayerPlaybackProperties):Void {
	    speed = src.speed;
	    volume = src.volume;
	    shuffle = src.shuffle;
	    muted = src.muted;
	    repeat = src.repeat;
	    scale = src.scale;
	}

	/**
	  * serialize [this]
	  */
	@:keep
	public function hxSerialize(s : Serializer):Void {
	    inline function w(x : Dynamic) s.serialize( x );
	    w( speed );
	    w( volume );
	    w( shuffle );
	    w( muted );
	    w( repeat );
	    w( scale );
	}

	/**
	  * unserialize [this]
	  */
	@:keep
	public function hxUnserialize(u : Unserializer):Void {
	    inline function v():Dynamic return u.unserialize();
	    changed = new Signal();
	    speed = v();
	    volume = v();
	    shuffle = v();
	    muted = v();
	    repeat = v();
	    scale = v();
	}

	/**
	  * sce -- schedule change event
	  * schedule that 'changed' be fired with the given PPChange item during the next call stack
	  */
	private inline function sce(change : PPChange):Void {
	    defer(changed.call.bind( change ));
	}

/* === Computed Instance Fields === */

	public var volume(default, set): Float;
	private function set_volume(v : Float):Float {
	    var ov = volume;
	    volume = v.clamp(0.0, 1.0);
	    var hc = (ov != volume);
	    if ( hc ) {
	        sce(Volume(new Delta(volume, ov)));
        }
	    return volume;
	}

	public var speed(default, set): Float;
	private function set_speed(v : Float):Float {
	    var ov = speed;
	    speed = v;
	    var hc = (ov != speed);
	    if ( hc ) {
	        sce(Speed(new Delta(speed, ov)));
        }
	    return speed;
	}

	public var shuffle(default, set): Bool;
	private function set_shuffle(v : Bool):Bool {
	    var hc = (shuffle != v);
	    shuffle = v;
	    if ( hc ) {
	        sce(Shuffle( shuffle ));
	    }
	    return shuffle;
	}

	public var muted(default, set): Bool;
	private function set_muted(v : Bool):Bool {
	    var hc = (muted != v);
	    muted = v;
	    if ( hc ) {
	        sce(Muted( muted ));
	    }
	    return muted;
	}

	public var repeat(default, set): RepeatType;
	private function set_repeat(v : RepeatType):RepeatType {
	    var hc = (repeat != v);
	    repeat = v;
	    if ( hc ) {
	        sce(Repeat( repeat ));
	    }
	    return repeat;
	}

	public var scale(default, set):Float;
	private function set_scale(v : Float):Float {
	    var ov = scale;
	    var hc = (scale != v);
	    scale = v;
	    if ( hc ) {
	        sce(Scale(new Delta(scale, ov)));
	    }
	    return scale;
	}

/* === Instance Fields === */

	public var changed : Signal<PPChange>;
}

/**
  * enum of kinds of changes to PlayerPlaybackProperties
  */
enum PPChange {
    Volume(d : Delta<Float>);
    Speed(d : Delta<Float>);
    Shuffle(newval : Bool);
    Muted(newval : Bool);
	Repeat(newval : RepeatType);
	Scale(d : Delta<Float>);
}

@:enum
abstract RepeatType (Int) from Int to Int {
    var RepeatOff = 0;
    var RepeatIndefinite = 1;
    var RepeatOnce = 2;
    var RepeatPlaylist = 3;
}
//enum RepeatType {
	//RepeatOff;
	//RepeatIndefinite;
	//RepeatOnce;
	//RepeatPlaylist;
//}
