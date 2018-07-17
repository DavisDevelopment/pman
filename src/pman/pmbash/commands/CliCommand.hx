package pman.pmbash.commands;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.math.*;
import tannus.sys.Path;
import tannus.TSys as Sys;

import pman.core.*;
import pman.media.*;
import pman.bg.media.*;
import pman.async.tasks.*;
import pman.format.pmsh.*;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;
import pman.pmbash.commands.*;
import pman.pmbash.args.*;

import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.async.Asyncs;

@name('cli')
class CliCommand extends Command {
    /**
      equivalent to 'static function main(){...}' for [this] Command
     **/
    function _root(d:Directive, params:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String, Dynamic>, done:VoidCb):Void {
        trace('CliCommand [main]');
        trace(params.map.fn(_.value));

        done();
    }

    /**
      main entry-point of execution for [this] Commmand
     **/
    override function execute(i:Interpreter, args:Array<CmdArg>, done:VoidCb):Void {
        _prep_(i, args);

        _cli(done.wrap(function(_, ?error) {
            trace('CliCommand exited');
            _( error );
        }));
    }

    /**
      parse [this] Command's arguments and evaluate the command-line API spec
     **/
    function _cli(done: VoidCb):Void {
        var meta = tm();
        var args = argv.copy();
        trace(args.map.fn(_.value));

        var subnames:Array<String> = [],
        flagnames:Array<Array<String>> = [];

        if (meta.exists('commands')) {
            subnames = subnames.concat(meta['commands'].map.fn('' + _));
        }

        if (meta.exists('flags')) {
            for (val in meta['flags']) {
                if ((val is Array<Dynamic>)) {
                    flagnames.push(cast(val, Array<Dynamic>).map.fn('' + _));
                }
            }
        }

        var parser = new CmdArgParser(this, subnames, flagnames);
        _cli_parser( parser );
        var executor = new DirectiveExecutor(_clapi());
        var expr = parser.parse( argv );
        echo( expr );
        executor.exec(expr, done);
    }

    /**
      do stuff with the arg-parser before it parses the arg-list
     **/
    function _cli_parser(parser: CmdArgParser) {
        return ;
    }

    /**
      method that builds the specification of [this] Command's CLAPI (command-line API)
     **/
    function _clapi():DirectiveSpec {
        var spec = new DirectiveSpec(name);
        spec.executor(function(dir, args, flags, kwargs, callback) {
            _root(dir, args, flags, kwargs, callback);
        });
        /*
        spec.sub('betty', function(betty) {
            betty.param('uri');
            betty.executor( exec_betty );
            betty.sub('jesus', function(jesus) {
                jesus.executor(argsOnly(function(args, done:VoidCb) {
                    player.gotoNext();
                    defer(done.void());
                }));
            });
        });
        */
        return spec;
    }

    function exec_betty(d:Directive, args:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String,Dynamic>, done:VoidCb) {
        var line: String = '';
        function use_line() {
            line = line.nullEmpty().ifEmpty('shit-caked pussy boogers');

            engine.dialogs.notify('crusty spooge', {
                body: '[== BETTY ==]\n  "$line"\n',
                badge: 'urinal',
                requireInteraction: true
            })
            .then(function(noti) {
                noti.onshow = (function() {
                    player.message('urinal cumshots');
                });
                noti.onclick = (function() {
                    noti.close();
                    trace('gizzard dumpling');
                    done();
                });
                noti.onclose = (function() {
                    trace('too slow, no blow');
                    done();
                });
            }, done.raise());
        }

        if (kwargs.exists('uri')) {
            trace(kwargs['uri']);
            line = ('' + kwargs['uri']);
            use_line();
        }

        player.prompt('nigger soup', 'vaginal custard nuggets', null, function(txt) {
            line = txt;
            use_line();
        });
    }

    /**
      wrap the given function in the longer-form version of it that accepts the full set of arguments
     **/
    function argsOnly(func: (argv:Array<CmdArg>, callback:VoidCb)->Void):(d:Directive, args:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String,Dynamic>, done:VoidCb)->Void {
        return ((directive, argumentList, flagSet, namedArgumentMap, callback) -> func(argumentList, callback));
    }
}
