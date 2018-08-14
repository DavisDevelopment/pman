package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;
import tannus.async.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

import haxe.ds.Option;
import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

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
using tannus.FunctionTools;

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
    private function resolve(name:String, ?done:Cb<Cmd>):Promise<Option<Cmd>> {
        //done(null, commands[name]);
        return pota(Promise.resolve(commands[name]), null, done);
    }

    /**
      * get a value from a Word
      */
    //private function resolveWordValue(word : Word):Dynamic {
        //return wordToString( word );
    //}

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
      * resolve parameter values
      */
    function resolveArgValues(words:Array<Word>, ?done:Cb<Array<EValue<Dynamic>>>):Promise<Array<EValue<Dynamic>>> {
        //defer(function() {
            //var values = words.map( resolveWordValue );
            //defer(done.yield().bind(values));
        //});
        var fanon:Void -> Promise<Array<EValue<Dynamic>>>;
        var promres = ((fanon = function() {
            // the number of [words] to evaluate
            var length = words.length,
            // [the number of values obtains thus far
                numvals = 0,
            // [new array of proper length, with values initialized to null
                results = [for (i in 0...length) EvUntyped(null)];

            // create the promise instance
            return new Promise(function(accept, reject) {
                /* convert each eval-promise into a promise for a value */
                var promises:Array<Promise<EValue<Dynamic>>> = words.map(function(word: Word) {
                    
                    return ptop(evalWord( word )).transform(function(o: Option<Dynamic>) {
                        switch o {
                            case Some(x): return EvUntyped(x);
                            case Some(null)|None: return EvUntyped(EvNil);
                        }
                    });
                });

                /* resolve the promise for the evaluated value of each [word] respectively */
                promises.reducei(
                    function(acc:Array<EValue<Dynamic>>, promise:Promise<EValue<Dynamic>>, index:Int):Array<EValue<Dynamic>> {
                        /* resolve [promise] to a [value] and place [value] into [results] */
                        promise.then(function(value: EValue<Dynamic>) {
                            acc[index] = value;
                            ++numvals;
                            if (numvals == length) {
                                accept( results );
                                //accept()
                            }
                        }, reject);

                        return acc;
                    },
                    results
                );
            });
        })());
        promres.toAsync( done );
        return promres;
    }

    /**
      * expand command arguments
      */
    private function expand(params:Array<Expr>, ?done:Cb<Array<Word>>):Promise<Array<Word>> {
        var result:Array<Word> = new Array();
        inline function add(a: Array<Word>) {
            if ((a is Word)) {
                result.push(cast(a, Word));
            }
            else if (a.length == 1) {
                result.push(a[0]);
            }
            else {
                result = result.concat( a );
            }
        }

        function esp(p:Expr, cb:VoidCb) {
            switch p {
                case EWord(word):
                    switch word {
                        case Word.Interpolate(ipoExpr):
                            // output generated shell-code to file on desktop
                            Fs.write(Paths.desktop().plusString('pmbash(interpolate).sh'), ipoExpr.print());
                            result.push(Interpolate(ipoExpr));

                        case Ref(name):
                            add([Ident(environment[name].ifEmpty(''))]);
                            //result.push(Ident(val));

                        default:
                            result.push( word );
                    }

                default:
                    null;
            }

            cb();
        }

        return new Promise(function(accept, reject) {
            params.map.fn(p => esp.bind(p, _)).series(function(?error) {
                if (error != null)
                    reject( error );
                else
                    accept( result );
            });
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

    inline static function pota<T>(promise:Promise<T>, ?isnil:T->Bool, ?callback:Cb<T>):Promise<Option<T>> {
        return ota(ptop(promise, isnil), callback);
    }

    inline static function ota<T>(promise:Promise<Option<T>>, ?callback:Cb<T>):Promise<Option<T>> {
        return cast callback != null ? promise.then(function(o: Option<T>) {
            callback(null, switch o {
                case None: null;
                case Some(v): v;
            });
        }, callback.raise()) : promise;
    }

    static function ptop<T>(promise:Promise<T>, ?isnil:T->Bool):Promise<Option<T>> {
        if (isnil == null)
            isnil = (x -> true);
        //isnil = fn(_ != null && isnil(_));
        isnil = isnil.wrap(function(_, x:T):Bool {
            return (x != null && _( x ));
        });
        return promise.transform(x -> (isnil( x ) ? Option.None : Option.Some(x)));
    }

    static function optp<T>(promise:Promise<Option<T>>, ?error:Lazy<Dynamic>):Promise<T> {
        if (error == null)
            error = PmShError.EWhatTheFuck('A value was expected, but none was provided', null);
        return promise.derive(function(_, accept, reject) {
            _.then(function(o: Option<T>) {
                switch o {
                    case Some(value): 
                        accept(value);

                    case None:
                        reject(error.get());
                }
            }, reject);
        });
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
