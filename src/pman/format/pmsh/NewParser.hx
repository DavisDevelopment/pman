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
            }
        }
    }

    inline function readStr(delimiter:Byte, ?escape:Byte):String {
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

    inline function isWordChar(c:Byte):Bool {
        return !c.isAny("$", ';', '=');
    }

    inline function ignore(t: Token) {
        while ( true ) {
            var nt = token();
            if (!nt.equals( t )) {
                push( nt );
                break;
            }
        }
    }

    inline function push(t: Token) {
        if (tks == null)
            tks = [];
        tks.push( t );
    }

    inline function readChar():Byte {
        if (chars != null && !chars.empty()) {
            return chars.shift();
        }
        else {
            return try input.readByte() catch (error: haxe.io.Eof) 0;
        }
    }

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
