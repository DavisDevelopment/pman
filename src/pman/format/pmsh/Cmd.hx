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
import pman.format.pmsh.CmdIo;
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

/**
  class to represent a PmSh (PMan Shell) command
 **/
class Cmd {
    /* Constructor Function */
    public function new():Void {
        name = 'cmd';
        _stdio = IOStream(_createStreamIo());
        outputValue = null;
        exitCode = null;
    }

/* === Instance Methods === */

    /**
      execute [this] Cmd
      TODO make this method final, and make a '_run' method
     **/
    public function execute(interp:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        _prep_(interp, args);

        done();
    }

    /**
      prepare [this] Cmd for execution
     **/
    function _prep_(i:Interpreter, args:Array<CmdArg>) {
        _init_();
        this.interpreter = i;
        this.argv = args;
    }

    /**
      initialize [this] Cmd
     **/
    function _init_() {
        _stdio = IOStream(_createStreamIo());
        outputValue = null;
    }

    /**
      kill [this] Cmd process
     **/
    function kill(code:Int, callback:VoidCb) {
        [
            _stdout.close.bind(_),
            _stderr.close.bind(_),
            _stdin.close.bind(_),
            (next -> _terminate(code, next)),
            _kill.bind(code, _)
        ].series( callback );
    }

    private function _destroy(error:Null<Dynamic>, callback:VoidCb):Void {
        callback( error );
    }

    private function _kill(code:Int, callback:VoidCb):Void {
        //TODO actually kill the Cmd
        //[
          //_terminate.bind(code, _),
          //_destroy.bind(null, callback)
        //].series( callback );
        exitCode = code;
        _destroy(null, callback);
    }

    dynamic function _terminate(code:Int, callback:VoidCb):Void {
        //TODO
        // default implementation
        callback();
    }

    /**
      write the given data <code>x</code> onto the specified output (defaults to <code>_stdout</code>)
     **/
    public function print(x:Dynamic, ?port:IoPortType, ?done:VoidCb):Void {
        if (port == null) {
            port = IoPortType.IoStdOut;
        }
        
        var out:CmdOutput = (switch port {
            case IoStdOut|IoStdAll: _stdout;
            case IoStdErr: _stderr;
            case _: throw EUnexpected( port );
        });
        out.write(bytes(x), done);
    }
    private function printer(x:Dynamic, ?port:IoPortType):VoidAsync return (cb -> print(x, port, cb));

    /**
      append a line of text to [this]
     **/
    public function println(x:Dynamic, ?port:IoPortType, ?done:VoidCb):Void {
        if (done == null) {
            print( x );
            print('\n');
        }
        else {
            [printer(x, port), printer('\n', port)].series( done );
        }
    }

    /**
      convert [x] to a ByteArray and return it
     **/
    private function bytes(x: Dynamic):Null<ByteArray> {
        if (x == null) {
            return ByteArray.alloc(0);
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

    /* create new writable stream */
    private function _createStreamOut():WritableStream<ByteArray> {
        return new WritableStream({});
    }

    /* create new writable stream */
    private function _createStreamErr():WritableStream<ByteArray> {
        return new WritableStream({});
    }

    /* create new writable stream */
    private function _createStreamIn():ReadableStream<ByteArray> {
        return new ReadableStream({});
    }

    /**
      build a streamed STDIO
     **/
    private function _createStreamIo():CmdStreamIo {
        return {
            input: _createStreamIn(),
            output: _createStreamOut(),
            error: _createStreamErr()
        };
    }

    /* create an input object */
    function _createSyncIn():Input {
        return new StringInput('');
    }

    /* create an output object */
    function _createSyncOut():Output {
        return new BytesOutput();
    }

    /* create an output object */
    function _createSyncErr():Output {
        return new BytesOutput();
    }

    /**
      create a synchronous IO
     **/
    function _createSyncIo():CmdSyncIo {
        return {
            input: _createSyncIn(),
            output: _createSyncOut(),
            error: _createSyncErr()
        };
    }

    /**
      get the _stdin value
     **/
    function _getInput():CmdInput {
        return switch _stdio {
            case IOSync(io): ITInput(io.input, io);
            case IOStream(io): ITReadableStream(io.input, io);
        };
    }

    /**
      get the _stdout value
     **/
    function _getOutput():CmdOutput {
        return switch _stdio {
            case IOSync(io): OTOutput(io.output, io, 1);
            case IOStream(io): OTWritableStream(io.output, io);
        }
    }

    /**
      get the _stderr value
     **/
    function _getError():CmdOutput {
        return switch _stdio {
            case IOSync(io): OTOutput(io.error, io, 2);
            case IOStream(io): OTWritableStream(io.error, io);
        }
    }

/* === Computed Instance Fields === */

    public var _stdout(get, never): CmdOutput;
    private dynamic function get__stdout() return _getOutput();

    public var _stderr(get, never): CmdOutput;
    private dynamic function get__stderr() return _getError();

    public var _stdin(get, never): CmdInput;
    private dynamic function get__stdin() return _getInput();

    /* internally-used [_stdio] property */
    public var _stdio(default, set): CmdIo;
    private function set__stdio(v) {
        var ret = (this._stdio = v);
        get__stdout = _getOutput.memoize();
        get__stderr = _getError.memoize();
        get__stdin = _getInput.memoize();
        return ret;
    }

/* === Instance Fields === */

    public var name : String;
    //public var _stdio : CmdStdIo;
    public var exitCode: Null<Int>;

    private var argv: Array<CmdArg>;
    private var interpreter: Interpreter;
    private var outputValue: Null<Dynamic>;
}

