package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

import pman.format.pmsh.Token;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Tokenizer extends LexerBase {
    /* Constructor Function */
    public function new():Void {

    }

/* === Instance Methods === */

    /**
      * tokenize the given String
      */
    public function tokenizeString(s : String):Array<Token> {
        return tokenize(ByteArray.ofString( s ));
    }

    /**
      * tokenize the given ByteArray
      */
    public function tokenize(bytes : ByteArray):Array<Token> {
        buffer = new ByteStack( bytes );
        tokens = new Array();

        while ( !done ) {
            var tk = lexToken();
            if (tk != null) {
                tokens.push( tk );
            }
        }

        return tokens;
    }

    /**
      * get next token
      */
    private function lexToken():Null<Token> {
        if ( done ) {
            return null;
        }
        else {
            var c = next();
            if (c.isWhiteSpace()) {
                advance();
                if (c.isLineBreaking()) {
                    return TDelimiter;
                }
                else {
                    return lexToken();
                }
            }
            else if (c.equalsChar(';')) {
                advance();
                return TDelimiter;
            }
            else if (c.equalsChar('&') && next(1).equalsChar('&')) {
                advance();
                advance();
                return TDelimiter;
            }
            else if (c.equalsChar('=')) {
                advance();
                return TSym( '=' );
            }
            else if (c.equalsChar("$")) {
                advance();
                if ( done ) {
                    throw 'Error: Unexpected end of input';
                }
                if (isWordChar(next())) {
                    var nt = lexToken();
                    switch ( nt ) {
                        case TWord( word ):
                            switch ( word ) {
                                case Ident( name ):
                                    return TWord(Ref( name ));

                                default:
                                    throw 'Error: Unexpected $nt';
                            }

                        default:
                            throw 'Error: Unexpected $nt';
                    }
                }
                else {
                    throw 'Error: Unexpected "${next()}"';
                }
            }
            else if (c.equalsChar('"') || c.equalsChar("'") || c.equalsChar('`')) {
                var del = advance();
                var delId:Int = (switch ( c ) {
                    case '"'.code: 0;
                    case "'".code: 1;
                    default: 2;
                });
                var str:String = readGroup(del, del, '\\'.code);
                return TWord(String(str, delId));
            }
            else if (isWordChar( c )) {
                var id:String = advance();
                var esc = false;
                while (!done && isWordChar(next(), esc)) {
                    if ( esc ) {
                        esc = false;
                    }
                    if (!esc && next().equalsChar('\\')) {
                        esc = true;
                        advance();
                    }
                    else {
                        id += advance();
                    }
                }
                return TWord(Ident( id ));
            }
            else {
                throw 'Error: Unexpected "$c"';
            }
        }
    }

    /**
      * check whether the given char is a valid word char
      */
    private function isWordChar(c:Byte, escaped:Bool=false):Bool {
        var notForbidden:Bool = (![
            "$".code,
            ';'.code,
            '='.code
        ].has( c ));
        if ( escaped ) {
            return true;
        }
        else {
            return (!c.isWhiteSpace() && notForbidden);
        }
    }

/* === Instance Fields === */

    public var tokens : Array<Token>;

/* === Static Methods === */

    public static function run(bytes : ByteArray):Array<Token> return new Tokenizer().tokenize( bytes );
    public static function runString(s : String):Array<Token> return new Tokenizer().tokenizeString( s );
}
