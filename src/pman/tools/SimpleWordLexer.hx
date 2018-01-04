package pman.tools;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.*;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class SimpleWordLexer extends LexerBase {
    /* Constructor Function */
    public function new():Void {
        //
    }

    public var words: Array<String>;
}

enum WordToken {
    TkWord(word: String);
    TkCompound(wordParts: Array<String>);
}
