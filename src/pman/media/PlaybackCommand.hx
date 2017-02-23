package pman.media;

enum PlaybackCommand {
	PCPlay;
	PCPause;
	PCTogglePlayback;
	PCStop;
	PCTime(time:Float, ?relative:Bool);
	PCSpeed(speed:Float, ?relative:Bool);
	PCVolume(volume:Float, ?relative:Bool);
}
