package pman.tools;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.*;

import tannus.math.TMath.*;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class SimpleWordLexer extends LexerBase {
    /* Constructor Function */
    public function new(?options: WordLexerOptionsDecl):Void {
        this.options = _opt(_.defaults((options == null ? {} : options), {
            word_delimiter_chars: '\u0009\u000A\u000B\u000C\u000D\u0020',
            quote_chars: '\'"`',
            punc_chars: ",.?!&@:;<>*+=/"
        }));
    }

    public function tokenize(text: String):Array<WordToken> {
        this.buffer = new ByteStack(ByteArray.ofString( text ));
        this.tokens = new Array();

        while (!done) {
            var t = nextToken();
            if (t != null) {
                tokens.push( t );
            }
        }

        return tokens;
    }

    /**
      * get the next valid token
      */
    private function nextToken():Null<WordToken> {
        var tk = tok();
        while (tk == null && !done) {
            tk = tok();
        }
        if (tk != null) {
            var prev:Null<WordToken> = null;
            while (!done && (prev == null || prev.equals( tk ))) {
                prev = tk;
                tk = patch_tok( prev );
            }
        }
        return tk;
    }

    private function tok():Null<WordToken> {
        if ( done )
            return null;

        var c:Byte = next();
        if (options.word_delimiters.has( c )) {
            cawd();
            return null;
        }
        else if (isWordChar( c )) {
            var txt = readWordString();
            if (txt == null) {
                return null;
            }
            else if (txt.has('-')) {
                var subs = txt.split('-');
                return compound( subs );
            }
            else if (isCamelCased( txt )) {
                var subs = txt.camelWords();
                return compound( subs );
            }
            else {
                return word( txt );
            }
        }
        else if (options.quote_chars.has( c )) {
            var delimiter:Byte = advance();
            var text:String = readGroup(delimiter, delimiter, '\\'.code, false);
            return group(WordGroupType.WgtQuote, text);
        }
        else if (c.isAny('(', '[', '{')) {
            var opener:String = advance();
            var closer:String = ([
                '(' => ')',
                '[' => ']',
                '{' => '}'
            ][opener]);
            var data = readGroup(opener.byteAt(0), closer.byteAt(0), null, true);
            if (data.length == 0) {
                return null;
            }
            var data:String = data.toString().trim().nullEmpty();
            if (data == null) {
                return null;
            }
            return group(WgtParent, data);
        }
        else if (isPuncChar( c )) {
            return punct(advance());
        }
        else {
            advance();
            return null;
        }
    }

    private function patch_tok(t: WordToken):WordToken {
        //TODO
        return t;
    }

    private function readWordString():Null<String> {
        var chars = new ByteArrayBuffer();
        while (!done && (isWordChar(next()) || next().equalsChar("'"))) {
            chars.addByte(advance());
        }

        if (chars.length == 0) {
            return null;
        }

        var chars:ByteArray = chars.getByteArray();
        return chars.toString().trim().nullEmpty();
    }

    private inline function isWordChar(c: Byte):Bool {
        return (
            c.isAlphaNumeric() ||
            c.isAny(
                '-', '_',
                '#', '@'
            )
        );
    }

    private inline function isPuncChar(c: Byte):Bool {
        return options.punc_chars.has( c );
    }

    private function isCamelCased(s: String):Bool {
        var n:Int = 0, nal:Int = 0, c:Byte;
        for (index in 0...s.length) {
            c = s.byteAt( index );
            if (c.isUppercase()) {
                ++n;
                nal = 0;
            }
            else if (c.isLowercase() && n > 0) {
                ++nal;
            }
        }
        return (n > 0 && nal > 0);
    }

    private inline function cawd():Void {
        while (!done && options.word_delimiters.has(next())) {
            advance();
        }
    }

    private inline function word(s: String):WordToken {
        return TkWord( s );
    }

    private inline function punct(x: String):WordToken {
        return TkPunctuation( x );
    }

    private inline function compound(parts: Array<String>):WordToken {
        return TkCompound( parts );
    }

    private function group(type:WordGroupType, text:String):WordToken {
        return TkWordGroup(type, subTokenize( text ));
    }

    private function subTokenize(s: String):Array<WordToken> {
        return copy().tokenize( s );
    }

    private function copy():SimpleWordLexer {
        var res = new SimpleWordLexer();
        res.options = {
            word_delimiters: options.word_delimiters.copy(),
            quote_chars: options.quote_chars.copy(),
            punc_chars: options.punc_chars.copy()
        };
        return res;
    }

    private static function _opt(d: WordLexerOptionsDecl):WordLexerOptions {
        var o:WordLexerOptions = {
            word_delimiters: new Set(),
            quote_chars: new Set(),
            punc_chars: new Set()
        };
        inline function add(x:String, s:Set<Byte>) {
            for (i in 0...x.length) {
                s.push(x.byteAt( i ));
            }
        }
        if (d.word_delimiter_chars != null) {
            add(d.word_delimiter_chars, o.word_delimiters);
        }
        if (d.quote_chars != null) {
            add(d.quote_chars, o.quote_chars);
        }
        if (d.punc_chars != null) {
            add(d.punc_chars, o.punc_chars);
        }
        return o;
    }

    public static function lex(text:String, ?options:WordLexerOptionsDecl):Array<WordToken> {
        return new SimpleWordLexer( options ).tokenize( text );
    }

    private var options: WordLexerOptions;
    public var tokens: Array<WordToken>;
}

enum WordToken {
    TkPunctuation(punc: String);
    TkWord(word: String);
    TkCompound(wordParts: Array<String>);
    TkWordGroup(type:WordGroupType, words:Array<WordToken>);
}

enum WordGroupType {
    WgtParent;
    WgtQuote;
}

typedef WordLexerOptionsDecl = {
    ?word_delimiter_chars: String,
    ?quote_chars: String,
    ?punc_chars: String
};

typedef WordLexerOptions = {
    word_delimiters: Set<Byte>,
    quote_chars: Set<Byte>,
    punc_chars: Set<Byte>
};
