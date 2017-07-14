package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;

import haxe.Serializer;
import haxe.Unserializer;

import tannus.math.TMath.*;

import pman.search.SearchTerm;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.TMath;
using pman.search.SearchTools;

class SearchTermTokenizer extends LexerBase {
    /* Constructor Function */
    public function new():Void {
        tokens = new Array();
        buffer = new ByteStack( '' );
    }

/* === Instance Methods === */

    private function runString(s : String) return run(ByteArray.ofString( s ));
    private function run(data : ByteArray):Array<SearchTermToken> {
        buffer = new ByteStack( data );
        tokens = new Array();

        while ( !done ) {
            var tk = token();
            if (tk != null)
                tokens.push( tk );
        }

        return tokens;
    }

    private function token():Null<SearchTermToken> {
        if ( done ) {
            return null;
        }
        else {
            var c = advance();
            if (c.isWhiteSpace()) {
                var wsc:Int = 1;
                while (!done && next().isWhiteSpace()) {
                    advance();
                    ++wsc;
                }
                return Whitespace;
            }
            else if (c.equalsChar('(')) {
                return OParent;
            }
            else if (c.equalsChar(')')) {
                return CParent;
            }
            else if (c.equalsChar('&')) {
                return And;
            }
            else if (c.equalsChar('|')) {
                return Or;
            }
            else if (c.equalsChar('!')) {
                return Not;
            }
            else if (c.equalsChar('=')) {
                return Eq;
            }
            else if (c.equalsChar('<')) {
                return Lt;
            }
            else if (c.equalsChar('>')) {
                return Gt;
            }
            else if (c.equalsChar("$")) {
                return Dollar;
            }
            else if (c.equalsChar('^')) {
                return Circum;
            }
            else if (c.equalsChar('*')) {
                return Asterisk;
            }
            else if (c.equalsChar('~')) {
                return Tilde;
            }
            else if (c.equalsChar('\\')) {
                return FSlash;
            }
            else if (c.equalsChar('/')) {
                return BSlash;
            }
            else if (c.equalsChar('[')) {
                return OBox;
            }
            else if (c.equalsChar(']')) {
                return CBox;
            }
            else if (c.equalsChar('{')) {
                return OBracket;
            }
            else if (c.equalsChar('}')) {
                return CBracket;
            }
            else if (c.equalsChar(':')) {
                return Colon;
            }
            else if (c.equalsChar(',')) {
                return Comma;
            }
            else if (c.equalsChar('"') || c.equalsChar("'")) {
                var sep = c;
                var str:String = '', esc:Bool = false;
                while ( true ) {
                    if ( done ) {
                        throw 'unexpected end of input';
                    }
                    else if ( esc ) {
                        str += advance();
                        esc = false;
                    }
                    else {
                        c = advance();
                        if (c.equalsChar('\\'))
                            esc = true;
                        else if (c == sep)
                            break;
                        else
                            str += c;
                    }
                }
                return String( str );
            }
            else if (c.isAlphaNumeric() || !symPattern.match(c)) {
                var word = '$c';
                while (!done && (next().isAlphaNumeric() || !symPattern.match(next()))) {
                    word += advance();
                }

                // handle keywords
                /*var kwsymbol:Null<SearchTermToken> = (switch ( word ) {
                    case 'AND': And;
                    case 'OR': Or;
                    case 'NOT': Not;
                    case 'EQUALS': Eq;
                    case 'LESSTHAN': Lt;
                    case 'MORETHAN': Gt;
                    default: Word( word );
                });
                return kwsymbol;
                */
                // this looks like a call, check what name
                if (!done && next().equalsChar('(') && fmacros.has( word )) {
                    var fmp = readParen();
                    tokens.push(Word(word));
                    tokens.push(OParent);
                    return FMacroParam( fmp );
                }

                return Word( word );
            }
            else {
                throw 'unexpected "$c"';
            }
        }
        return null;
    }

    private function readParen(start_depth:Int=0):String {
        if (start_depth == 0 && !done && next() == 40) {
            advance();
            ++start_depth;
        }

        var depth:Int = start_depth;
        var result = '', c:Byte, esc:Bool=false;
        while (!done && depth > 0) {
            c = next();
            if ( esc ) {
                result += advance();
                esc = false;
            }
            else if (c == 40)
                depth++;
            else if (c == 41)
                depth--;
            else if (c == '\\'.code)
                esc = true;
            else {
                if (depth > 0)
                    result += advance();
            }
        }
        return result;
    }

/* === Instance Fields === */

    private var tokens : Array<SearchTermToken>;
    private var symPattern:EReg = ~/[()\[\]{}:&|!~*^=<>]/;

    public static var fmacros:Array<String> = {[
        'GLOB',
        'ORE',
        'RE'
    ];};

/* === Static Methods === */

    public static function tokenize(data : ByteArray):Array<SearchTermToken> return new SearchTermTokenizer().run( data );
    public static function tokenizeString(s : String):Array<SearchTermToken> return new SearchTermTokenizer().run( s );
}
