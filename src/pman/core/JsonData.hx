package pman.core;

typedef JsonData = {};

typedef JsonSession = {
	playlist : Array<String>,
	playbackProperties : JsonPlaybackProperties,
	?nowPlaying : JsonPlayerState
};

typedef JsonPlaybackProperties = {
	speed : Float,
	volume : Float,
	shuffle : Bool
};

typedef JsonPlayerState = {
	track : Int,
	time : Float
};

@:enum
abstract LoadTrigger (String) from String to String {
    var User = 'user';
    var History = 'history';
}
