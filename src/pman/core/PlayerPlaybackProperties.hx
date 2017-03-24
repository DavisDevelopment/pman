package pman.core;

using tannus.math.TMath;

class PlayerPlaybackProperties {
	/* Constructor Function */
	public function new(speed:Float, volume:Float, shuffle:Bool):Void {
		this.speed = speed;
		this.volume = volume;
		this.shuffle = shuffle;
	}

/* === Instance Methods === */

	public function clone():PlayerPlaybackProperties {
		return new PlayerPlaybackProperties(speed, volume, shuffle);
	}

/* === Computed Instance Fields === */

	public var volume(default, set): Float;
	private inline function set_volume(v : Float):Float {
	    return (volume = v.clamp(0.0, 1.0));
	}

/* === Instance Fields === */

	public var speed : Float;
	public var shuffle : Bool;
}
