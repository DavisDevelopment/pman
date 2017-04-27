package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

import pman.format.pmsh.Token;
import pman.format.pmsh.Expr;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Parser {
    /* Constructor Function */
    public function new():Void {

    }

/* === Instance Methods === */

    /**
      * parse the given tokens
      */
    public function parse(tokens : Array<Token>):Expr {
        this.tokens = new Stack( tokens );
        this.tree = new Array();

        while ( !done ) {
            var e = parseExpr();
            if (e != null) {
                tree.push( e );
            }
        }

        return EBlock( tree );
    }

    /**
      * parse next expr
      */
    private function parseExpr():Null<Expr> {
        var e = expr();
        if (e != null) {
            var en = exprNext( e );
            while (!e.equals( en )) {
                e = en;
                en = exprNext( e );
            }
            e = en;
        }
        return e;
    }

    /**
      * get next expression
      */
    private function expr():Null<Expr> {
        if ( done ) {
            return null;
        }
        else {
            var tk = tokens.peek();
            switch ( tk ) {
                case TWord( word ):
                    tokens.pop();
                    if ( !done ) {
                        var ntk = tokens.peek();
                        switch ( ntk ) {
                            // variable assignment
                            case TSym( '=' ):
                                tokens.pop();
                                var name = word;
                                if ( !done ) {
                                    var vtk = tokens.peek();
                                    switch ( vtk ) {
                                        case TWord(value):
                                            tokens.pop();
                                            return ESetVar(name, value);

                                        default:
                                            throw 'Error: Unexpected $vtk';
                                    }
                                }
                                else {
                                    throw 'Error: Unexpected end of input';
                                }

                            // command invokation
                            default:
                                var args = new Array();
                                while (!done && !(tokens.peek().equals( TDelimiter ))) {
                                    var arg = parseCmdArg();
                                    if (arg == null) {
                                        break;
                                    }
                                    else {
                                        args.push( arg );
                                    }
                                }
                                if (tokens.peek().equals( TDelimiter )) {
                                    tokens.pop();
                                }
                                return ECommand(word, args);
                        }
                    }
                    else {
                        return ECommand(word, []);
                    }

                default:
                    throw 'Error: Unexpected $tk';
            }
        }
    }

    /**
      * 
      */
    private function exprNext(e : Expr):Expr {
        return e;
    }

    /**
      * parse command argument
      */
    private function parseCmdArg():Null<Expr> {
        if ( done ) {
            return null;
        }
        else {
            var tk = tokens.peek();
            switch ( tk ) {
                case TWord( word ):
                    tokens.pop();
                    return EWord( word );

                case TDelimiter:
                    tokens.pop();
                    return parseCmdArg();

                default:
                    throw 'Error: Unexpected $tk';
            }
        }
    }

    /**
      * tokenize the given String
      */
    private function lexString(s : String):Array<Token> {
        return Tokenizer.runString( s );
    }

    /**
      * get the singular token tokenized from the given String
      */
    private function tokenFromString(s : String):Token {
        var toks = lexString( s );
        if (toks.length != 1) {
            throw 'Error: invalid number of tokens';
        }
        else {
            return toks[0];
        }
    }

    /**
      * parse a Word from the given String
      */
    private function wordFromString(s : String):Word {
        var t = tokenFromString( s );
        switch ( t ) {
            case TWord( word ):
                return word;

            default:
                throw 'Error: unexpected non-word token $t';
        }
    }

/* === Computed Instance Fields === */

    public var done(get, never):Bool;
    private inline function get_done() return tokens.empty;

/* === Instance Fields === */

    public var tokens : Stack<Token>;
    public var tree : Array<Expr>;

/* === Static Methods === */

    public static function run(tokens:Array<Token>):Expr return new Parser().parse( tokens );
    public static function runString(s : String):Expr return run(Tokenizer.runString( s ));
}
