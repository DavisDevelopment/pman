package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

import pman.async.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;

import electron.Tools.*;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.async.VoidAsyncs;

class Interpreter {
    /* Constructor Function */
    public function new():Void {
        environment = new Dict();
        commands = new Map();

        __init();
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    private function __init():Void {
        __initEnvironment();
        __initCommands();
    }

    /**
      * initialize environment
      */
    private function __initEnvironment():Void {
        var env = Sys.environment();
        for (key in env.keys()) {
            environment[key] = env[key];
        }
    }
    
    /**
      * set a variable
      */
    private inline function setenv(k:String, v:String) return environment.set(k, v);

    /**
      * write many variables, from any key->value data structure
      */
    private function env(vars : Dynamic):Void {
        if ((vars is haxe.ds.StringMap<Dynamic>)) {
            var sm:Map<String, String> = vars;
            for (k in sm.keys()) {
                setenv(k, sm[k]);
            }
        }
        else if ((vars is tannus.ds.dict.IDict<String, Dynamic>)) {
            var sd:Dict<String, Dynamic> = vars;
            for (k in sd.keys()) {
                setenv(k, Std.string(sd[k]));
            }
        }
        else {
            var o:Object = vars;
            for (key in o.keys) {
                if (!Reflect.isFunction(o[key])) {
                    setenv(key, o[key]);
                }
            }
        }
    }

    /**
      * initialize commands
      */
    private function __initCommands():Void {
        //TODO
    }


    /**
      * execute the given expression
      */
    public function execute(e:Expr, complete:VoidCb):Void {
        async( e )( complete );
    }

    /**
      * execute the given String
      */
    public function executeString(s:String, complete:VoidCb):Void {
        execute(Parser.runString(s), complete);
    }

    /**
      * build the given expression out into a VoidAsync
      */
    private function async(expr : Expr):VoidAsync {
        switch ( expr ) {
            case EBlock( body ):
                return ((body.map( async )).series.bind());

            case ESetVar(name, value):
                return function(done:VoidCb):Void {
                    var sname = wordToString( name );
                    var svalue = wordToString( value );
                    environment[sname] = svalue;
                    done();
                };

            case ECommand(nameWord, params):
                var name = wordToString( nameWord );
                return function(done : VoidCb):Void {
                    expand(params, function(?error, ?paramWords) {
                        if (error != null) {
                            done( error );
                        }
                        else {
                            resolve(name, function(?error, ?command) {
                                if (error != null) {
                                    done( error );
                                }
                                else {
                                    if (command != null) {
                                        resolveArgValues(paramWords, function(?error, ?args) {
                                            if (error != null)
                                                done( error );
                                            else {
                                                var commandArgs = paramWords.zipmap(args, fn([word, value] => new CmdArg(EWord(word), value)));
                                                command.execute(this, commandArgs, done);
                                            }
                                        });
                                    }
                                    else {
                                        done('Error: No command "$name" found');
                                    }
                                }
                            });
                        }
                    });
                };

            default:
                throw 'Error: Unexpected $expr';
        }
    }

    /**
      * resolve a Cmd from name
      */
    private function resolve(name:String, done:Cb<Cmd>):Void {
        defer(function() {
            done(null, commands[name]);
        });
    }

    /**
      * get a value from a Word
      */
    private function resolveWordValue(word : Word):Dynamic {
        return wordToString( word );
    }

    /**
      * resolve parameter values
      */
    private function resolveArgValues(words:Array<Word>, done:Cb<Array<Dynamic>>):Void {
        defer(function() {
            var values = words.map( resolveWordValue );
            defer(done.yield().bind(values));
        });
    }

    /**
      * expand command arguments
      */
    private function expand(params:Array<Expr>, done:Cb<Array<Word>>):Void {
        var result:Array<Word> = new Array();
        function esp(p:Expr, cb:VoidCb) {
            defer(function() {
                switch ( p ) {
                    case EWord( word ):
                        switch ( word ) {
                            case Ref(name):
                                var val = (environment.exists(name)?environment[name]:'');
                                result.push(Ident(val));
                            default:
                                result.push( word );
                        }

                    default:
                        null;
                }
                defer(cb.void());
            });
        }
        params.map.fn(p=>esp.bind(p,_)).series(function(?error) {
            trace( result );
            if (error != null)
                done(error, null);
            else
                done(null, result);
        });
    }

    /**
      * convert a Word into a String
      */
    private function wordToString(word : Word):String {
        switch ( word ) {
            case Ident(s), String(s, _):
                return s;
            case Ref(name):
                if (environment.exists( name )) {
                    return environment[name];
                }
                else {
                    return '';
                }
        }
    }

    /**
      * creates a 'partial'
      */
    public function createPartialFromExpr(e : Expr):PmshPartial {
        switch ( e ) {
            case ECommand(nameWord, params), EBlock([ECommand(nameWord, params)]):
                return new PmshPartial(nameWord, params);

            default:
                throw 'TypeError: partials may only be created from command-invokation expressions';
        }
    }

    /**
      * create a partial from a String
      */
    public function parsePartial(exprString : String):PmshPartial {
        return createPartialFromExpr(Parser.runString( exprString ));
    }

/* === Instance Fields === */

    public var commands : Map<String, Cmd>;
    public var environment : Dict<String, String>;
}

@:access( pman.format.pmsh.Interpreter )
@:structInit
class PmshPartial {
    public var cmd:Word;
    public var params:Array<Expr>;

    public function new(cmd:Word, params:Array<Expr>):Void {
        this.cmd = cmd;
        this.params = params;
    }

    /**
      * create a command-invokation expression from [this] partial
      */
    public function toExpr(?additionalParams : Array<Expr>):Expr {
        var fullParams = params;
        if (additionalParams != null)
            fullParams = fullParams.concat( additionalParams );
        return ECommand(cmd, fullParams);
    }

    /**
      * create an actual function that can be executed with additional arguments
      */
    public function bind():Interpreter->Array<CmdArg>->VoidCb->Void {
        var icmd:Null<Cmd> = null;
        var paramWords:Null<Array<Word>> = null;

        return (function(i:Interpreter, argv:Array<CmdArg>, done:VoidCb) {
            if (icmd == null && paramWords == null) {
                i.resolve(i.wordToString( cmd ), function(?err, ?command:Cmd) {
                    if (err != null) {
                        done( err );
                    }
                    else if (command == null) {
                        done('${i.wordToString( cmd )}: command not found');
                    }
                    else {
                        icmd = command;
                        i.expand(params, function(?err, ?words) {
                            if (err != null)
                                return done( err );
                            else {
                                paramWords = words;
                                i.resolveArgValues(paramWords, function(?error, ?values) {
                                    if (error != null) {
                                        done( error );
                                    }
                                    else {
                                        var zipper = fn([w,v]=>new CmdArg(EWord(w), v));
                                        icmd.execute(i, paramWords.zipmap(values, zipper), done);
                                    }
                                });
                            }
                        });
                    }
                });
            }
            else {
                i.resolveArgValues(paramWords, function(?error, ?values) {
                    if (error != null) {
                        done( error );
                    }
                    else {
                        var zipper = fn([w,v]=>new CmdArg(EWord(w), v));
                        icmd.execute(i, paramWords.zipmap(values, zipper), done);
                    }
                });
            }
        });
    }
}
