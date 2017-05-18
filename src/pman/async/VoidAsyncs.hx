package pman.async;

import tannus.ds.Stack;

import haxe.macro.Expr;
import haxe.macro.Context;

using Lambda;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

using haxe.macro.ExprTools;
using tannus.macro.MacroTools;

/*
   pman.async.VoidAsyncs
  ---
   mixin class of helper functions regarding VoidAsync functions
*/
class VoidAsyncs {
    /**
      * execute every item in [i] as a series, each one running only after the previous one has finished
      */
    public static function series(i:Iterable<VoidAsync>, done:VoidCb):Void {
        var s = new Stack(i.array());
        var f : VoidAsync;
        function next():Void {
            if ( s.empty ) {
                done();
            }
            else {
                f = s.pop();
                f(function(?error) {
                    if (error != null)
                        done( error );
                    else
                        next();
                });
            }
        }
        next();
    }

    /**
      * invoke all items in [i] simultaneously, and invoke [done] when all have completed
      */
    public static function callEach(i:Iterable<VoidAsync>, done:VoidCb):Void {
        var n = [0, 0];
        function handle(?error:Dynamic) {
            if (error != null) {
                done( error );
            }
            else {
                n[1] += 1;
                if (n[0] == n[1]) {
                    done();
                }
            }
        }
        for (va in i) {
            n[0] += 1;
            va( handle );
        }
    }

    /**
      * forward error to given VoidCb
      */
    public static macro function forward(callback:ExprOf<VoidCb>, error:ExprOf<Null<Dynamic>>) {
        return macro if ($error != null) return $callback( $error );
    }
}
