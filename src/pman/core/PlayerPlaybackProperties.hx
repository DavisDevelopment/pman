package pman.core;

import tannus.io.Signal;
import tannus.ds.Delta;

import electron.Tools.defer;

using tannus.math.TMath;

class PlayerPlaybackProperties {
	/* Constructor Function */
	public function new(speed:Float, volume:Float, shuffle:Bool, muted:Bool=false, ?repeat:RepeatType):Void {
	    changed = new Signal();

		this.speed = speed;
		this.volume = volume;
		this.shuffle = shuffle;
		this.muted = muted;
		this.repeat = (repeat != null) ? repeat : RepeatOff;
	}

/* === Instance Methods === */

    /**
      * create and return a copy of [this]
      */
	public function clone():PlayerPlaybackProperties {
		return new PlayerPlaybackProperties(speed, volume, shuffle, muted, repeat);
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
}

enum RepeatType {
	RepeatOff();
	RepeatIndefinite();
	RepeatOnce();
	RepeatPlaylist();
}
