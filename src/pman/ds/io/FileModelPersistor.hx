package pman.ds.io;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.TSys as Sys;

import pman.events.EventEmitter;
import pman.Paths;
import pman.ds.Transform.TransformSync as Transform;
import pman.ds.io.SerialTransform.HxSerialization;
import pman.ds.io.ByteArrayTransform.PlainText;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.Json;
import haxe.rtti.Meta;

import edis.storage.fs.async.FileSystem;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.macro.MacroTools;

class FileModelPersistor<T:Model> extends ModelPersistor<T> {
    /* Constructor Function */
    public function new(m, fs:FileSystem):Void {
        super(m);

        path = (Paths.userData().plusString( saveInfo.name ).normalize());
        port = new FilePort(fs, path);
        var pt = new PlainText();
        var hs:Transform<T, String> = Transform.create({
            encode: function(m: T) {
                return m.serialize();
            },
            decode: function(s: String):T {
                return cast Model.deserializeStringToModel( s );
            }
        });
        transform = cast hs.compose(cast pt.flip());
        modem = new Modem(cast port, transform);
    }

/* === Instance Methods === */

/* === Instance Fields === */

    public var path: Path;
    public var port: FilePort;
    public var transform: Transform<T, ByteArray>;
}
