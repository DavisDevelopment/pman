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


class SearchTermParser extends LexerBase {
    /* Constructor Function */
    public function new():Void {
        terms = new Array();
    }

/* === Instance Methods === */

    public function parseString(s : String):Array<SearchTerm> {
        return parse(ByteArray.ofString( s ));
    }

    /**
      * parse the given ByteArray
      */
    public function parse(bytes : ByteArray):Array<SearchTerm> {
        terms = new Array();
        buffer = new ByteStack( bytes );

        while ( !done ) {
            term();
        }

        return terms;
    }

    private function term():Void {
        var t = nextTerm();
        if (t != null) {
            terms.push( t );
        }
    }

    private function nextTerm(?t : SearchTerm):Null<SearchTerm> {
        if (t == null) {
            if ( done ) {
                return null;
            }

            var c = next();

            // Whitespace
            if (c.isWhiteSpace()) {
                advance();
                return nextTerm();
            }

            // Words
            else if (c.isAlphaNumeric()) {
                var word:String = advance();
                while (!done && isWordCharacter(next())) {
                    word += advance();
                }
                return nextTerm(Word( word ));
            }

            // unsupported shit
            else {
                advance();
                return nextTerm();
            }
        }
        else {
            return t;
        }
    }

/* === Utility Methods === */

    private inline function isWordCharacter(c : Byte):Bool {
        return (c.isAlphaNumeric() || WORD_SYMBOLS.has( c ));
    }

/* === Instance Fields === */

    public var terms : Array<SearchTerm>;

/* === Static Fields === */

	private static inline var WORD_SYMBOLS:String = '#,./-';

/* === Static Methods === */

    public static inline function run(bytes : ByteArray):Array<SearchTerm> return (new SearchTermParser().parse( bytes ));
    public static inline function runString(s : String):Array<SearchTerm> return (new SearchTermParser().parseString( s ));
}
