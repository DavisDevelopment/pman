package pman.async;

import tannus.math.Percent;
import tannus.io.*;
import tannus.ds.*;
import tannus.async.Task2 as T2;

import pman.Globals.*;
import pman.async.Result;

interface Trackable<T> {
    public var progress(default, set):Float;
    public var startTime(default, null):Float;

    public var onProgress : Signal<Delta<Percent>>;
    public var onError : Signal<Dynamic>;
    public var onResult : Signal<T>;
}
