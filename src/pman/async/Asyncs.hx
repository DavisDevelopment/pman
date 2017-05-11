package pman.async;

import tannus.ds.Stack;

using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

/*
   pman.async.VoidAsyncs
  ---
   mixin class of helper functions regarding VoidAsync functions
*/
class Asyncs {
    /**
      * execute every item in [i] as a series, each one running only after the previous one has finished
      */
    public static function series<T>(i:Iterable<Async<T>>, done:Cb<Array<T>>):Void {
        var s = new Stack(i.array());
        var res:Array<T> = new Array();
        var f : Async<T>;
        function next():Void {
            if ( s.empty ) {
                done(null, res);
            }
            else {
                f = s.pop();
                f(function(?error, ?result:T) {
                    if (error != null)
                        done( error );
                    else {
                        res.push( result );
                        next();
                    }
                });
            }
        }
        next();
    }

    public static function callEach<T>(i:Iterable<Async<T>>, done:Cb<Array<T>>):Void {
        var index = [0, 0];
        var values = [];
        function _handle(n:Int, ?error:Dynamic, ?result:T):Void {
            if (error != null)
                done( error );
            else {
                values[n] = result;
                index[1] += 1;
                if (index[0] == index[1]) {
                    done(null, values);
                }
            }
        }
        for (a in i) {
            a(_handle.bind(index[0], _, _));
            index[0] += 1;
        }
    }
}
