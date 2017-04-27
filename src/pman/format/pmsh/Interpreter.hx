package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.TSys as Sys;

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
                return ((body.map.fn( async )).series.bind());

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
                                                command.execute(this, args, done);
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

/* === Instance Fields === */

    public var commands : Map<String, Cmd>;
    public var environment : Dict<String, String>;
}
