package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.node.*;
import tannus.node.WritableStream;
import tannus.node.ReadableStream;
import tannus.node.Duplex;
import tannus.node.Transform;

import edis.streams.*;

import pman.async.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;

import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

/**
  class to represent a PmSh (PMan Shell) command
 **/
class Cmd {
    /* Constructor Function */
    public function new():Void {
        name = 'cmd';
        stdio = _createStdIo();
    }

/* === Instance Methods === */

    /**
      execute [this] Cmd
      TODO make this method final, and make a '_run' method
     **/
    public function execute(interp:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        done();
    }

    private function _destroy(error:Null<Dynamic>, callback:VoidCb):Void {
        callback( error );
    }

    private function _kill(code:Int, callback:VoidCb):Void {
        //TODO actually kill the Cmd
        _destroy(null, callback);
    }

    public function print(x: Dynamic):Void {
        stdout.write(bytes(x));
    }

    public function println(x: Dynamic):Void {
        print( x );
        print('\n');
    }

    /**
      convert [x] to a ByteArray and return it
     **/
    private function bytes(x: Dynamic):Null<ByteArray> {
        if (x == null) {
            return null;
        }
        else if ((x is Binary)) {
            return cast x;
        }
        else if ((x is Buffer)) {
            return cast tannus.io.impl.NodeBinary.ofData(cast x);
        }
        else if ((x is String)) {
            return ByteArray.ofString( x );
        }
        else if ((x is haxe.io.Bytes)) {
            return ByteArray.fromBytes(cast x);
        }
        else {
            inline function has(name: String):Bool {
                return Reflect.hasField(x, name);
            }

            try {
                if (has('toBytes')) {
                    return bytes(x.toBytes());
                }
                else if (has('toByteArray')) {
                    return bytes(x.toByteArray());
                }
                else if (has('toBinary')) {
                    return bytes(x.toBinary());
                }
                else {
                    return ByteArray.ofString(Std.string( x ));
                }
            }
            catch (error: Dynamic) {
                return ByteArray.ofString(Std.string( x ));
            }
        }
    }

    private function _createStdOut():WritableStream<ByteArray> {
        return new WritableStream({});
    }

    private function _createStdErr():WritableStream<ByteArray> {
        return new WritableStream({});
    }

    private function _createStdIn():ReadableStream<ByteArray> {
        return new ReadableStream({});
    }

    private function _createStdIo():CmdStdIo {
        return {
            input: _createStdIn(),
            output: _createStdOut(),
            error: _createStdErr()
        };
    }

/* === Computed Instance Fields === */

    public var stdout(get, never): WritableStream<ByteArray>;
    private inline function get_stdout() return stdio.output;

    public var stderr(get, never): WritableStream<ByteArray>;
    private inline function get_stderr() return stdio.error;

    public var stdin(get, never): ReadableStream<ByteArray>;
    private inline function get_stdin() return stdio.input;

/* === Instance Fields === */

    public var name : String;
    public var stdio : CmdStdIo;

    private var argv: Array<CmdArg>;
    private var interpreter: Interpreter;
}

@:structInit
class CmdArg {
    public var expr : Expr;
    public var value : Dynamic;

    public inline function new(e:Expr, v:Dynamic) {
        expr = e;
        value = v;
    }
}

typedef CmdStdIo = {
    var error: WritableStream<ByteArray>;
    var output: WritableStream<ByteArray>;
    var input: ReadableStream<ByteArray>;
}
