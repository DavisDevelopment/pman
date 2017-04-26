package pman.tools.chromecast;

import tannus.node.*;
import pman.async.*;

import haxe.extern.EitherType;

extern class ExtDevice extends EventEmitter {
	public function play(resource:EitherType<String, MediaDef>, seconds:Float, callback:VoidCb):Void;
	public function getStatus(callback : Cb<DeviceStatus>):Void;
	public function seekTo(newCurrentTime:Float, callback:VoidCb):Void;
	public function seek(time:Float, callback:VoidCb):Void;
	public function pause(f : VoidCb):Void;
	public function unpause(f : VoidCb):Void;
	public function setVolume(volume:Float, cb:VoidCb):Void;
	public function stop(cb : VoidCb):Void;
	public function setVolumeMuted(muted:Bool, cb:VoidCb):Void;
	public function close(cb : VoidCb):Void;

	public var host : String;
	public var config : DeviceConfig;
}

typedef DeviceStatus = {
    currentTime:Float,
    currentItemId:Int,
    media: {
        contentId: String,
        contentType: String,
        duration:Float
    },
    playbackRate: Float,
    mediaSessionId: Int,
    playerState: String,
    repeatMode: String,
    supportedMediaCommands: Int,
    videoInfo: {
        hdrType: String,
        height: Int,
        width: Int
    },
    volume: {level:Int, muted:Bool}
};

typedef MediaDef = {
	url : String,
	?cover : MediaDefCoverInfo
};

typedef MediaDefCoverInfo = {
	?title : String,
	?url : String
};

typedef DeviceConfig = {
	?addresses : Array<String>,
	name : String
};
