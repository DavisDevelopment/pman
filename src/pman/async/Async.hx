package pman.async;

import tannus.ds.*;

typedef Async<T> = tannus.async.Async<T>;

/*
@:callable
abstract Async<T> (Cb<T>->Void) from Cb<T>->Void {
    public inline function new(f : Cb<T>->Void)
        this = f;

    @:to
    public function promise():Promise<T> {
        return new Promise(function(yield, raise) {
            this(function(?error, ?result) {
                if (error != null)
                    return raise( error );
                else if (result != null)
                    return yield( result );
                else {
                    trace('Promise left unresolved!');
                }
            });
        });
    }

    @:to
    public function promiser():Void->Promise<T> {
        return promise.bind();
    }
}
*/
