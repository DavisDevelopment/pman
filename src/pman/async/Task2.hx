package pman.async;

import tannus.math.Percent;
import tannus.io.*;
import tannus.ds.*;
import tannus.async.Task2 as T2;

import pman.Globals.*;
import pman.async.Result;

class Task2<T> extends T2<T> implements Trackable<T> {
    /* Constructor Function */
    public function new() {
        super();

        startTime = 0.0;
        onComplete = new Signal();
        onError = new Signal();
        onResult = new Signal();
        onComplete.on(function(res : Result<Dynamic,T>) {
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

    override function run(?cb : Cb<T>):Void {
        var _cb = cb;
        cb = function(?error:Dynamic, ?value:T) {
            if (error != null)
                onComplete.call(Result.Error( error ));
            else
                onComplete.call(Result.Value( value ));
        };
        if (_cb != null) {
            onComplete.once(function(res : Result<Dynamic,T>) {
                switch ( res ) {
                    case Error(error):
                        _cb(error, null);
                    case Value(value):
                        _cb(null, value);
                }
            });
        }
        startTime = now();
        execute( cb );
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

    public var statusMessage(default, set):String;
    private function set_statusMessage(v) {
        return (this.statusMessage = v);
    }

/* === Instance Fields === */

    public var startTime(default, null):Float;
    public var onComplete : Signal<Result<Dynamic, T>>;
    public var onError : Signal<Dynamic>;
    public var onResult : Signal<T>;
    public var onProgress : Signal<Delta<Percent>>;
}
