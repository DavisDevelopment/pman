package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.core.*;
import pman.async.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;
import haxe.rtti.Meta;

import Slambda.fn;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using pman.async.VoidAsyncs;
using tannus.FunctionTools;

class Command extends Cmd {
    /* constructor function */
    public function new() {
        super();

        _actions = new Dict();
        _actNames = new Array();
        _flagNames = new Array();

        //act('::main::', _main_);
        _register_();

        _meta_();
    }

/* === Instance Methods === */

    function _register_() {
        //TODO
    }

    override function execute(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        _prep_(i, args);
    }

    override function _prep_(i:Interpreter, args:Array<CmdArg>):Void {
        super._prep_(i, args);
    }

    function _meta_() {
        var meta:Anon<Array<Dynamic>> = tm();
        if (meta.exists('name')) {
            this.name = meta['name'].join('');
        }
    }

    function _main_(done: VoidCb):Void {
        done();
    }

    inline function tm():Anon<Array<Dynamic>> {
        return Anon.of(Meta.getType(Type.getClass(this)));
    }

    inline function _doAction_(name:String, argv:Array<CmdArg>, done:VoidCb):Void {
        var body = _actf( name );
        
        _action_(body)(argv, new Dict(), new Set(), done);
    }

    inline function act(name:Either<String, Array<String>>, body:VoidCb->Void):Void {
        var names = _sa( name );
        var cname:String = names[0];
        for (row in _actNames) {
            if (row[0] == names[0]) {
                names.shift();
                for (name in names) {
                    if (!row.has( name )) {
                        row.push( name );
                    }
                }
            }
        }
        _actions[cname] = body;
    }

    inline function _actf(name: String):Null<VoidCb->Void> {
        if (_actions.exists( name )) {
            return _actions[name];
        }
        else {
            return _actions[_canonicalActionName_(name)];
        }
    }

    static function _sa(s: Either<String, Array<String>>):Array<String> {
        if ((s is String)) {
            return cast(s, String).split(',').map.fn(_.trim());
        }
        else {
            return cast(s, Array<Dynamic>).map(item -> _sa((item : String))).flatten();
        }
    }

    function _canonicalActionName_(name: String):String {
        for (row in _actNames) {
            for (rn in row) {
                if (rn == name) {
                    return row[0];
                }
            }
        }
        return name;
    }

    inline function _word(index:Int, ?argv:Array<CmdArg>):Null<String> {
        if (argv == null)
            argv = this.argv;
        if ((argv[index].value is String)) {
            return cast(argv[index], String);
        }
        else return null;
    }

    inline function _action_(f: VoidCb->Void):(args:Array<CmdArg>, kwargs:Dict<String, Dynamic>, flags:Set<String>, done:VoidCb)->Void {
        return (function(a, kw, fl, cb:VoidCb):Void {
            cmdArgs = a;
            cmdKwArgs = kw;
            cmdFlags = fl;
            return f( cb );
        });
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return bpmain.player;

/* === Instance Fields === */

    var _actions: Dict<String, VoidCb->Void>;
    var _actNames: Array<Array<String>>;
    var _flagNames: Array<Array<String>>;

    var cmdArgs: Array<CmdArg>;
    var cmdKwArgs: Dict<String, Dynamic>;
    var cmdFlags: Set<String>;
}
