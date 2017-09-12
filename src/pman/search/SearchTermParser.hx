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

class PmQlParser {
    /* Constructor Function */
    public function new() {

    }

/* === Instance Methods === */

    /**
      * execute that shit
      */
    public function run(toks : Array<SearchTermToken>):Array<SearchTerm> {
        tree = new Array();
        tokens = new Stack( toks );

        while ( !done ) {
            var e = nextExpr();
            if (e != null)
                tree.push( e );
        }

        return tree;
    }

    private function expr(?prev : SearchTerm):Null<SearchTerm> {
        if ( done )
            return null;

        else if (prev == null) {
            var tok = pop();
            if (tok == null) return null;
            switch ( tok ) {
                case Word( word_txt ):
                    // fmacro call
                    if (SearchTermTokenizer.fmacros.has( word_txt )) {
                        switch (readTuple()) {
                            case [Constant(CString(param))]:
                                return _fmacro(word_txt, param);

                            default:
                                throw 'eat my ass about it';
                        }
                    }
                    else {
                        return Word(word_txt);
                    }

                case FMacroParam(arg):
                    return Constant(CString( arg ));

                default:
                    throw 'Unrecognized or unexpected ${tok}';
            }
        }
        else {
            if ( false ) {
                return null;
            }
            else return prev;
        }
    }

    private function readTuple(?groupers:Bool) {
        if (groupers == null) {
            return readTuple(nextNonWhitespace().match( OParent ));
        }
        else {
            var result = [];
            if ( groupers ) {
                pop();
            }
            while (!done && !nextNonWhitespace().equals( CParent )) {
                var te = nextExpr();
                result.push( te );
                if (nextNonWhitespace().equals( Comma )) {
                    pop();
                    nextNonWhitespace();
                    continue;
                }
            }
            nextNonWhitespace();
            if (peek().equals(CParent)) {
                pop();
            }
            return result;
        }
    }

    private function nextExpr():Maybe<SearchTerm> {
        var e:Maybe<SearchTerm> = null, ne:Maybe<SearchTerm> = null;
        e = expr();
        do {
            ne = expr( e );
            if (e == null || ne == null)
                return e.or(ne);
            else if (ne.equals( e ))
                return ne;
        }
        while (!(ne.equals( e )));
        return ne;
    }

    private function _fmacro(name:String, d:String):SearchTerm {
        switch ( name ) {
            case 'GLOB':
                return Constant(CGlob(new GlobStar(d, 'i')));
            case 'RE':
                return Constant(CEReg(new EReg(d, 'i')));
            case 'ORE':
                return Constant(COReg( d ));
            default: throw 'wut the buttsex';
        }
    }

    private function nextNonWhitespace():Maybe<SearchTermToken> return nextTokenThatIsNot( SearchTermToken.Whitespace );
    private function nextTokenThatIsNot(t : SearchTermToken):Maybe<SearchTermToken> {
        while (!done && peek().equals( t )) pop();
        return peek();
    }

    private inline function peek():Maybe<SearchTermToken> return tokens.peek();
    private inline function pop():Maybe<SearchTermToken> return tokens.pop();

/* === Computed Instance Fields === */

    private var done(get, never):Bool;
    private inline function get_done() return tokens.empty;

/* === Instance Fields === */

    private var tokens : Stack<SearchTermToken>;
    private var tree : Array<SearchTerm>;
}

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
