package pman.ds;

import tannus.io.*;

import electron.Tools.*;

@:forward
abstract OnceSignal (COnceSignal) {
    public inline function new() {
        this = {s: new VoidSignal(), v:false};
        this.s.once(function() {
            this.v = true;
        });
    }

    public inline function announce():Void this.s.fire();

    public inline function await(action : Void->Void):Void {
        if ( this.v ) {
            defer( action );
        }
        else {
            this.s.once(defer.bind( action ));
        }
    }
}

typedef COnceSignal = {
    s : VoidSignal,
    v : Bool
};
