package pman.bg.media;

@:enum
abstract RepeatType (Int) from Int to Int {
    var RepeatOff = 0;
    var RepeatIndefinite = 1;
    var RepeatOnce = 2;
    var RepeatPlaylist = 3;
}
