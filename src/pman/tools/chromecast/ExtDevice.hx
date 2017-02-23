package pman.tools.chromecast;

import tannus.node.*;

import haxe.extern.EitherType;

extern class ExtDevice extends EventEmitter {
	public function play(resource:EitherType<String, MediaDef>, seconds:Float, callback:ErrCb):Void;
	public function getStatus(callback : Null<Dynamic>->DeviceStatus->Void):Void;
	public function seekTo(newCurrentTime:Float, callback:ErrCb):Void;
	public function seek(time:Float, callback:ErrCb):Void;
	public function pause(f : ErrCb):Void;
	public function unpause(f : ErrCb):Void;
	public function setVolume(volume:Float, cb:ErrCb):Void;
	public function stop(cb : ErrCb):Void;
	public function setVolumeMuted(muted:Bool, cb:ErrCb):Void;
	public function close(cb : ErrCb):Void;

	public var host : String;
	public var config : DeviceConfig;
}

typedef DeviceStatus = Dynamic;

@:callable
abstract ErrCb (Null<Dynamic> -> Void) from Null<Dynamic>->Void {}

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
