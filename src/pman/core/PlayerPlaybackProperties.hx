package pman.core;

import tannus.io.VoidSignal;

using tannus.math.TMath;

class PlayerPlaybackProperties {
	/* Constructor Function */
	public function new(speed:Float, volume:Float, shuffle:Bool, muted:Bool=false):Void {
	    changed = new VoidSignal();

		this.speed = speed;
		this.volume = volume;
		this.shuffle = shuffle;
		this.muted = muted;
	}

/* === Instance Methods === */

    /**
      * create and return a copy of [this]
      */
	public function clone():PlayerPlaybackProperties {
		return new PlayerPlaybackProperties(speed, volume, shuffle, muted);
	}

	/**

/* === Computed Instance Fields === */

	public var volume(default, set): Float;
	private function set_volume(v : Float):Float {
	    var hc = (volume != v.clamp(0.0, 1.0));
	    volume = v.clamp(0.0, 1.0);
	    if ( hc )
            changed.fire();
	    return volume;
	}

	public var speed(default, set): Float;
	private function set_speed(v : Float):Float {
	    var hc = (speed != v);
	    speed = v;
	    if ( hc )
            changed.fire();
	    return speed;
	}

	public var shuffle(default, set): Bool;
	private function set_shuffle(v : Bool):Bool {
	    var hc = (shuffle != v);
	    shuffle = v;
	    if ( hc ) {
	        changed.fire();
	    }
	    return shuffle;
	}

	public var muted(default, set): Bool;
	private function set_muted(v : Bool):Bool {
	    var hc = (muted != v);
	    muted = v;
	    if ( hc ) {
	        changed.fire();
	    }
	    return muted;
	}

/* === Instance Fields === */

	public var changed : VoidSignal;
}
