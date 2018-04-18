package pman.sys;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.Path;
import tannus.async.*;
import tannus.async.promises.*;

import edis.storage.fs.*;
import edis.storage.fs.async.*;
import edis.storage.fs.async.EntryType;
import edis.storage.fs.async.EntryType.WrappedEntryType as Wet;
import edis.Globals.*;

import pman.sys.ValueExtractor;
import pman.sys.ValueExtractor as Ve;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.extern.EitherType;

import tannus.io.Ptr.*;
import tannus.async.Promise;

import Slambda.fn;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.async.Asyncs;
using tannus.FunctionTools;
using tannus.ds.IteratorTools;

class ValueExtractorTools {
    /**
      * ${1}
      */
    public static function evaluate<T>(value:ValueExtractor<T>, ctx:Dynamic):Promise<T> {
        switch ( value ) {
            case Ve.VConst( c ):
                return promise(untyped c);

            case Ve.VProperty( name ):
                return cast preq({name: evaluate(name, ctx)}).transform(function(props) {
                    return Reflect.getProperty(ctx, Std.string(props.name));
                });

            default:
                throw 'PooYai';
        }
    }

    private static function preq<T:Dynamic<Promise<Dynamic>>>(propertyPromises: T):Promise<Dynamic<Dynamic>> {
        return new Promise(function(accept, reject) {
            var result:Object = {};
            var opp:Object = propertyPromises;
            var pp:Promise<Dynamic>;
            var keys = opp.keys;

            function complete() {
                accept((result : Dynamic<Dynamic>));
            }

            function settled(k:String, v:Dynamic) {
                result[k] = v;
                keys.remove( k );
                if (keys.empty()) {
                    complete();
                }
            }

            for (name in opp.keys) {
                pp = opp[name];
                if ((pp is Promise<Dynamic>)) {
                    pp.then(function(pv: Dynamic) {
                        settled(name, pv);
                    }, reject);
                }
                else {
                    defer(settled.bind(name, (untyped {pp;})));
                }
            }
        });
    }
}
