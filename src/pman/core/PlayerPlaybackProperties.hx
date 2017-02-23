package pman.core;

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

/* === Instance Fields === */

	public var speed : Float;
	public var volume : Float;
	public var shuffle : Bool;
}
