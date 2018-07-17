package pman.format.pmsh;

import tannus.io.*;
import tannus.io.Byte;
import tannus.ds.*;
import tannus.ds.Maybe;

import pman.format.pmsh.Expr;
import pman.format.pmsh.Token;

import haxe.extern.EitherType as Either;
import haxe.io.Input;
import haxe.io.StringInput;
import haxe.ds.Option;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using tannus.ds.SortingTools;
using tannus.async.OptionTools;
using tannus.FunctionTools;

class NewParser {
    /* Constructor Function */
    public function new() {
        //betty
    }

/* === Instance Methods === */

    public static inline function run(i: Input):Expr {
        return (new NewParser().parse( i ));
    }

    public static inline function runString(s: String):Expr {
        return run(new StringInput( s ));
    }

    public function parseString(s: String):Expr {
        return parse(new StringInput( s ));
    }

    /**
      parse an AST from the given Input
     **/
    public function parse(i: Input):Expr {
        input = i;
        _index = 0;
        chars = new Array();
        tks = new Array();

        var tk:Token, e:Expr, all:Array<Expr> = new Array();
        while ( true ) {
            tk = token();
            switch ( tk ) {
                case TEndOfInput:
                    break;

                default:
                    push( tk );
                    e = expr();
                    all.push( e );
            }
        }
        
        return EBlock( all );
    }

    /**
      parse the next expression in the sequence
     **/
    function expr():Expr {
        var tk = token();
        switch tk {
            case TDelimiter:
                return expr();

            case TWord(Ident(name)):
                var struct = parseStructure( name );
                if (struct != null) {
                    return struct;
                }
                else {
                    tk = token();
                    switch tk {
                        case TEndOfInput:
                            push( tk );
                            return ECommand(Ident(name), []);

                        case TDelimiter:
                            push( tk );
                            return ECommand(Ident(name), []);

                        case TSym('='):
                            return ESetVar(Ident(name), word());

                        case _:
                            push( tk );
                            push(TWord(Ident(name)));
                            return cmdExpr();
                    }
                }

            case TWord(word):
                return ECommand(word, cmdArgs());

            case TSym('{'):
                push( tk );
                return blockExpr();

            case _:
                throw PmShError.EUnexpected( tk );
        }
    }

    /**
      parse out a command expression
     **/
    function cmdExpr():Expr {
        var tk = token();
        switch tk {
            case TWord(word):
                return ECommand(word, cmdArgs());

            case _:
                throw EUnexpected( tk );
        }
    }

    /**
      parse out a block-level expression
     **/
    function blockExpr():Expr {
        var tk = token();
        switch tk {
            case TSym('{'):
                var body = [];
                while ( true ) {
                    tk = token();
                    switch tk {
                        case TEndOfInput:
                            throw PmShError.EUnterminatedBlock;

                        case TDelimiter:
                            continue;

                        case TSym('}'):
                            return EBlock(body);

                        case _:
                            body.push(expr());
                    }
                }
                return EBlock(body);

            case _:
                throw PmShError.EUnexpected(tk);
        }
    }

    /**
      parse out the next word-expression
     **/
    function wordExpr():Expr {
        var tk = token();
        switch tk {
            case TWord(word):
                return EWord( word );

            default:
                throw PmShError.EUnexpected( tk );
        }
    }

    function word():Word {
        var tk = token();
        return switch tk {
            case TWord(word): word;
            case _: throw EUnexpected(tk);
        };
    }

    /**
      parse out a list of command-arguments
     **/
    function cmdArgs():Array<Expr> {
        var args:Array<Expr> = new Array();
        while ( true ) {
            var tk = token();
            switch tk {
                case TDelimiter:
                    return args;

                case TEndOfInput:
                    push( tk );
                    return args;

                case _:
                    push( tk );
                    args.push(wordExpr());
            }
        }
        return args;
    }

    /**
      parse out a special structure
     **/
    function parseStructure(struct: String):Null<Expr> {
        switch struct {
            default:
                return null;
        }
    }

    /**
      get the next Token in the input buffer
     **/
    function token():Token {
        if (!tks.empty()) {
            return tks.shift();
        }
        else {
            var char:Byte = readChar();
            switch char {
                case 0:
                    return TEndOfInput;

                /* whitespace */
                case 9, 10, 13, 32:
                    if (char.isLineBreaking()) {
                        while ( true ) {
                            char = readChar();
                            if (!char.isWhiteSpace()) {
                                unshiftByte( char );
                                break;
                            }
                        }

                        return TDelimiter;
                    }
                    else {
                        return token();
                    }

                case "'".code, '"'.code:
                    var word = readStr(char);
                    return TWord(String(word, switch char {
                        case '\"'.code: 0;
                        case "\'".code: 1;
                        default: throw 'Unexpected $char';
                    }));

                case '&'.code:
                    char = readChar();
                    switch char {
                        case '&'.code:
                            return TDelimiter;

                        case _:
                            return TSym('&');
                    }

                case ';'.code:
                    return TDelimiter;

                /* equals sign */
                case '='.code:
                    return TSym('=');

                case "$".code:
                    switch token() {
                        case TWord(Ident(id)):
                            return TWord(Ref(id));

                        case tk:
                            push( tk );
                            throw 'Error: Unexpected $tk';
                    }

                /* read out word tokens */
                case _:
                    if (isWordChar( char )) {
                        unshiftByte( char );
                        return TWord(Ident(readWord()));
                    }
                    else {
                        throw EUnexpected('"${char.aschar}"');
                    }
            }
        }
    }

    function readWord():String {
        var word:StringBuf = new StringBuf(),
        escaped:Bool = false,
        char:Byte;

        while ( true ) {
            char = readChar();

            if (char == 0) {
                unshiftByte( char );
                break;
            }
            else if (!escaped && char.equalsChar('\\')) {
                escaped = true;
                continue;
            }
            else if ( escaped ) {
                word.addChar( char );
            }
            else if (char.isWhiteSpace()) {
                unshiftByte( char );
                break;
            }
            else if (!isWordChar( char )) {
                unshiftByte( char );
                break;
            }
            else {
                word.addChar( char );
            }
        }

        return word.toString();
    }

    /**
      read a String from the input buffer
     **/
    function readStr(delimiter:Byte, ?escape:Byte):String {
        if (escape == null)
            escape = '\\'.code;
        var res:StringBuf = new StringBuf(),
        escaped:Bool = false;
        while ( true ) {
            var c = readChar();
            if (c == 0) {
                throw 'UnterminatedString';
            }
            else if ( escaped ) {
                res.addChar( c );
                escaped = false;
            }
            else if (!escaped && c == escape) {
                escaped = true;
            }
            else if (c == delimiter) {
                return res.toString();
            }
            else {
                res.addChar( c );
            }
        }
        return res.toString();
    }

    /**
      check whether the given Byte is a Word character
     **/
    inline function isWordChar(c:Byte):Bool {
        return !(c.isAny("$", ';', '='));
    }

    /**
      betty
     **/
    inline function ignore(t: Token) {
        while ( true ) {
            var nt = token();
            if (!nt.equals( t )) {
                push( nt );
                break;
            }
        }
    }

    /**
      betty
     **/
    inline function push(t: Token) {
        if (tks == null)
            tks = [];
        tks.unshift( t );
    }

    /**
      read a character from the input buffer
     **/
    inline function readChar():Byte {
        if (chars != null && !chars.empty()) {
            return chars.shift();
        }
        else {
            return try input.readByte() catch (error: haxe.io.Eof) 0;
        }
    }

    /**
      push a Byte back onto the input buffer
     **/
    inline function unshiftByte(c: Byte) {
        if (chars == null)
            chars = [];
        if ((c : Int) >= 0)
            chars.unshift( c );
    }

/* === Instance Fields === */

    var originalInput: ByteArray;
    var input: Input;
    var _index: Int;

    var chars: Null<Array<Byte>>;
    var tks: Null<Array<Token>>;
}

enum PmShError {
    EUnexpected(x: Dynamic);

    EUnterminatedString;
    EUnterminatedBlock;
}
