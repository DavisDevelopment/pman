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
abstract CmdOutput (CmdOutputType) from CmdOutputType {
    @:to
    public function stream():WritableStream<ByteArray> {
        switch this {
            case OTWritableStream(x, _):
                return x;

            case OTOutput(out, io, fd):
                var ws = switch fd {
                    case 1: io.ows;
                    case 2: io.ews;
                    case _: throw EUnexpected(fd);
                };

                if (ws != null) {
                    return ws;
                }
                else {
                    var ws:WritableStream<ByteArray> = new WritableStream({
                        objectMode: true,
                        write: (function(self, chunk:ByteArray, encoding:String, done:VoidCb) {
                            out.bigEndian = chunk.bigEndian;
                            var bchunk = chunk.toBytes();
                            out.write( bchunk );
                            out.flush();
                            done();
                        }).fthis(),
                        writev: (function(self, chunks:Array<{chunk:ByteArray, ?encoding:String}>, done:VoidCb) {
                            for (chunk in chunks) {
                                out.bigEndian = chunk.chunk.bigEndian;
                                out.write(chunk.chunk.toBytes());
                            }
                            out.flush();
                            done();
                        }).fthis(),
                        destroy: (function(self:WritableStream<ByteArray>, error:Null<Dynamic>, callback:VoidCb) {
                            if (error != null)
                                callback( error );
                            else {
                                out.flush();
                                out.close();
                                callback();
                            }
                        }).fthis()
                    });

                    switch fd {
                        case 1:
                            io.ows = ws;
                        case 2:
                            io.ews = ws;
                        case _:
                            throw EUnexpected(fd);
                    }

                    return ws;
                }
        }
    }

    public function write(chunk:ByteArray, ?done:VoidCb) {
        switch this {
            case OTWritableStream(x, _):
                x.write(chunk, null, done);

            case OTOutput(x, _, _):
                x.prepare( chunk.length );
                x.write( chunk );
                if (done != null) {
                    x.flush();
                    done();
                }
        }
    }

    public function close(?done: VoidCb) {
        switch this {
            case OTWritableStream(x, _):
                x.end(done.nn());

            case OTOutput(x, _, _):
                x.flush();
                x.close();
                if (done != null)
                    done();
        }
    }
}
