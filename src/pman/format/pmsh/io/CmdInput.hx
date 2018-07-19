package pman.format.pmsh.io;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.node.*;
import tannus.node.WritableStream;
import tannus.node.ReadableStream;
import tannus.node.Duplex;
import tannus.node.Transform;

import edis.streams.*;
import haxe.io.*;

import pman.format.pmsh.NewParser;
import pman.format.pmsh.CmdIo;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;

import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.html.JSTools.JSFunctionTools;
using tannus.FunctionTools;

@:forward
abstract CmdInput (CmdInputType) from CmdInputType {
    @:to
    public function stream():ReadableStream<ByteArray> {
        switch this {
            case ITReadableStream(x, _):
                return x;

            case ITInput(i, io):
                if (io.irs != null) {
                    return io.irs;
                }
                else {
                    io.irs = new ReadableStream({
                        objectMode: true,
                        read: (function(self:ReadableStream<ByteArray>, ?len:Int) {
                            if (len == null) {
                                var b = i.readAll();
                                self.push(ByteArray.fromBytes(b));
                                return ;
                            }
                            else {
                                var b:Bytes;
                                do {
                                    try {
                                        b = i.read( len );
                                    }
                                    catch (eof: haxe.io.Eof) {
                                        b = i.readAll();
                                    }
                                }
                                while(self.push(ByteArray.fromBytes(b)));
                            }

                        }).fthis(),
                        destroy: (function(self:ReadableStream<ByteArray>, error:Null<Dynamic>, done:VoidCb) {
                            if (error != null)
                                return done( error );
                            else {
                                i.close();
                                done();
                            }
                        }).fthis()
                    });
                    return io.irs;
                }

            case _:
                throw EUnexpected( this );
        }
    }

    public function read(?len: Int):Null<ByteArray> {
        switch this {
            case ITReadableStream(x, _):
                return x.read(len);

            case ITInput(i, _):
                if (len == null)
                    return i.readAll();
                else
                    return i.read(len);
        }
    }

    public function close(?done: VoidCb) {
        switch this {
            case ITReadableStream(x, _):
                if (done != null) {
                    done = (function(_: VoidCb) {
                        return (function(nonOpt:Null<Dynamic>->Void) {
                            nonOpt = nonOpt.once();
                            return (function(?error) {
                                return nonOpt(error);
                            });
                        })(err -> _(err));
                    })(done);
                    x.onError(done.raise().once());
                    x.onEnd(done.void().once());
                }
                x.destroy();

            case ITInput(i, _):
                i.close();
                if (done != null)
                    done();
        }
    }
}
