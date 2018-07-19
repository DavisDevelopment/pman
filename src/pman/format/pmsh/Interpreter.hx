package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.TSys as Sys;

import pman.format.pmsh.NewParser;
import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Cmd;

import edis.Globals.*;
import pman.Globals.*;
import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using pman.format.pmsh.ExprTools;

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
    public inline function setenv(k:String, v:String) return environment.set(k, v);
    public inline function getenv(k: String):String return environment[k].ifEmpty('');

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
        eval(e, complete);
    }

    /**
      * execute the given String
      */
    public function executeString(s:String, complete:VoidCb):Void {
        //var expr:Expr = Parser.runString( s );
        var expr2:Expr = NewParser.runString( s );
        trace('' + expr2);
        execute(expr2, complete);
    }

    /**
      evaluate the given expression, and obtain its return-value
     **/
    function eval(expr:Expr, complete:VoidCb):Promise<ExprReturn> {
        switch expr {
            /* evaluate a word-expression */
            case EWord(word):
                //evalWord(word, complete);
                complete();

            /* evaluate a variable assignment */
            case ESetVar(name, value):
                environment[wordToString(name)] = wordToString(value);
                complete();

            /* binary operator */
            case EBinaryOperator(op, leftExpr, rightExpr):
                evalBinop(op, leftExpr, rightExpr, complete);

            /* unary operator */
            case EUnaryOperator(op, expr):
                throw EUnexpected( expr );

            /* block expression */
            case EBlock(exprs), ERoot(exprs):
                exprs.map(e -> (next -> eval(e, next))).series( complete );

            /* basic command */
            case ECommand(cmd):
                evalCmd(cmd, complete);

            /* function declaration */
            case EFunc(name, expr):
                commands[name] = new FuncCmd(this, name, expr);
                complete();

            /* for-loop statement */
            case EFor(id, iter, expr):
                complete();
        }

        return Promise.resolve(ERVoid);
    }

    function evalBinop(op:Binop, left:Expr, right:Expr, complete:VoidCb) {
        switch op {
            case OpAnd:
                evalAndOp(left, right, complete);

            case OpOr:
                evalOrOp(left, right, complete);

            case OpPipe:
                evalPipeOp(left, right, complete);

            case _:
                throw PmShError.EUnexpected(op);
        }
    }

    function evalPipeOp(left:Expr, right:Expr, complete:VoidCb) {
        eval(left, function(?error) {
            if (error != null)
                complete( error );
            else {
                trace('TODO: Piping not yet working');
                eval(right, complete);
            }
        });
    }

    function evalAndOp(left:Expr, right:Expr, complete:VoidCb) {
        eval(left, function(?error) {
            if (error != null)
                complete( error );
            else {
                eval(right, complete);
            }
        });
    }

    function evalOrOp(left:Expr, right:Expr, complete:VoidCb) {
        eval(left, function(?error) {
            if (error == null)
                complete();
            else {
                eval(right, complete);
            }
        });
    }

    /**
      evaluate a Command expression
     **/
    function evalCmd(cmd:CommandExpr, complete:VoidCb) {
        var name = resolve.bind(wordToString(cmd.command), _).toPromise();
        name.then(function(cmd: Cmd) {
            this.currentCmd = cmd;
        });
        var pwp:Promise<Array<Word>> = expand.bind(cmd.parameters, _).toPromise();
        var pwvp:Promise<Array<Dynamic>> = pwp.derive(function(p, resolve, reject) {
            p.then(function(words) {
                resolveArgValues(words, function(?error, ?values) {
                    if (error != null) {
                        reject( error );
                    }
                    else {
                        resolve( values );
                    }
                });
            }, reject);
        });
        var pwpp:Promise<Pair<Array<Word>, Array<Dynamic>>> = Promise.pair(new Pair(pwvp, pwp));
        var cap:Promise<Array<CmdArg>> = pwpp.transform(function(pair) {
            return pair.left.zipmap(pair.right, fn([word, value] => new CmdArg(EWord(word), value)));
        });
        var cmdt:Promise<Pair<Cmd, Array<CmdArg>>> = Promise.pair(new Pair(cap, name));
        var cmdExpr:CommandExpr = cmd;
        cmdt.then(function(pair) {
            var cmd:Null<Cmd> = pair.left,
            argv:Array<CmdArg> = pair.right;

            if (cmd == null) {
                return complete(ECommandNotFound( cmdExpr.command ));
            }
            else {
                cmd.execute(this, argv, complete.wrap(function(_, ?error) {
                    _(error);

                    currentCmd = null;
                }));
            }
        }, complete.raise());
    }

    /**
      * build the given expression out into a VoidAsync
      */
    private function async(expr : Expr):VoidAsync {
        return eval.bind(expr, _);
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
            //trace( result );
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

            case Interpolate(e):
                throw EWhatTheFuck('aww, poor design, sha', e);

            case Substitution(type, name, value):
                return wordToString(Ref(name));
        }
    }

    /**
      obtain a value from a Word instance
     **/
    function evalWord(word: Word):Promise<Dynamic> {
        return new Promise(function(resolve, reject) {
            switch word {
                case Ident(ident):
                    return resolve( ident );

                case String(str, delimiter):
                    switch delimiter {
                        case 0, 1:
                            return resolve( str );

                        case _:
                            return reject(EUnexpected( delimiter ));
                    }

                case Ref(name):
                    return resolve(getenv(name));

                case Interpolate(e):
                    return reject(EWhatTheFuck('command return-values need to be implemented before interpolation can be', e));

                case Substitution(type, name, valueExpr):
                    return resolve(untyped evalSubstitution(type, evalWord(Ident(name)), valueExpr));
            }
        });
    }

    function evalSubstitution(type:SubstitutionType, left:Promise<Dynamic>, right:Expr):Promise<Dynamic> {
        trace('TODO: properly implement value substitution in pmbash');
        return left;
    }

    /**
      * creates a 'partial'
      */
    public function createPartialFromExpr(e : Expr):PmshPartial {
        switch ( e ) {
            case ECommand(cmd), EBlock([ECommand(cmd)]), ERoot([ECommand(cmd)]):
                return new PmshPartial(cmd.command, cmd.parameters);

            default:
                throw 'TypeError: partials may only be created from command-invokation expressions';
        }
    }

    /**
      * create a partial from a String
      */
    public function parsePartial(exprString : String):PmshPartial {
        return createPartialFromExpr(NewParser.runString( exprString ));
    }

/* === Instance Fields === */

    public var commands : Map<String, Cmd>;
    public var environment : Dict<String, String>;

    var currentCmd: Null<Cmd> = null;
}

/**
  betty
 **/
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
        return ECommand(new CommandExpr(cmd, fullParams));
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

/**
  values that evaluating an expression can yield
 **/
enum ExprReturn {
    // no return value
    ERVoid;

    // the 'return' value from executing a command
    ERCommand(out: CmdReturn<Dynamic, Dynamic>);

    // the 'return' value from evaluating a word-expression
    ERWord(wval: EValue<Dynamic>);
}

enum CmdReturn<Val, Err> {
    CRReturn(value:EValue<Val>, error:Err):CmdReturn<Val, Err>;
    CROutput(stdOut:ByteArray, stdErr:ByteArray):CmdReturn<ByteArray, ByteArray>;
}
