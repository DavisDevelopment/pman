package pman.async;

import tannus.math.Percent;
import tannus.io.*;
import tannus.ds.*;
import tannus.async.Task1 as T1;

import pman.Globals.*;
import pman.async.Result;

class Task1 extends T1 implements Trackable<Dynamic> {
    /* Constructor Function */
    public function new():Void {
        super();

        startTime = 0.0;
        onComplete = new Signal();
        onError = new Signal();
        onResult = new Signal();
        onComplete.on(function(res : Result<Dynamic,Dynamic>) {
            switch ( res ) {
                case Error( error ):
                    onError.call( error );
                case Value( result ):
                    onResult.call( result );
            }
        });
        onProgress = new Signal();
        progress = 0.0;
    }

/* === Instance Methods === */

    /**
      * 
      */
    override function run(?done : VoidCb):Void {
        var _cb = done;
        done = function(?error : Dynamic) {
            if (error != null)
                onComplete.call(Result.Error( error ));
            else
                onComplete.call(Result.Value(null));
        };
        if (_cb != null) {
            onComplete.once(function(res : Result<Dynamic,Dynamic>) {
                switch ( res ) {
                    case Error(e):
                        _cb(e);
                    case Value(v):
                        _cb(null);
                }
            });
        }
        startTime = now();
        execute( done );
    }

/* === Computed Instance Fields === */

    public var progress(default, set):Float;
    private function set_progress(v : Float):Float {
        var _v = progress;
        progress = v;
        if (_v != progress) {
            onProgress.call(new Delta(new Percent(progress), new Percent(_v)));
        }
        return progress;
    }

/* === Instance Fields === */

    public var startTime(default, null):Float;
    public var onComplete : Signal<Result<Dynamic, Dynamic>>;
    public var onError : Signal<Dynamic>;
    public var onResult : Signal<Dynamic>;
    public var onProgress : Signal<Delta<Percent>>;
}
