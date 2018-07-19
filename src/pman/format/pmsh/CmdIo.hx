package pman.format.pmsh;

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
import pman.format.pmsh.io.CmdInput;
import pman.format.pmsh.io.CmdOutput;
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

enum CmdIo {
    IOSync(io: CmdSyncIo);
    IOStream(io: CmdStreamIo);
}

enum CmdInputType {
    ITReadableStream(stream:ReadableStream<ByteArray>, io:CmdStreamIo);
    ITInput(input:Input, io:CmdSyncIo);
}

enum CmdOutputType {
    OTWritableStream(stream:WritableStream<ByteArray>, io:CmdStreamIo);
    OTOutput(output: Output, io:CmdSyncIo, fd:Int);
}

@:structInit
class CmdSyncIo {
    public var error: haxe.io.Output;
    public var output: haxe.io.Output;
    public var input: haxe.io.Input;

    @:optional
    public var irs: ReadableStream<ByteArray>;
    @:optional
    public var ows: WritableStream<ByteArray>;
    @:optional
    public var ews: WritableStream<ByteArray>;
}

@:structInit
class CmdStreamIo {
    public var error: WritableStream<ByteArray>;
    public var output: WritableStream<ByteArray>;
    public var input: ReadableStream<ByteArray>;
}
