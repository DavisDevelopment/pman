package pman.search;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.nore.ORegEx;
import tannus.sys.GlobStar;

import pman.core.*;
import pman.media.*;
import pman.display.*;
import pman.display.media.*;

import haxe.Serializer;
import haxe.Unserializer;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using tannus.math.TMath;

enum SearchTerm {
    Constant(c : SearchTermConst);
    Word(word : String);
    Phrase(text : String);
    Parent(term : SearchTerm);
    Call(name:String, params:Array<SearchTerm>);

    Not(st : SearchTerm);
    And(left:SearchTerm, right:SearchTerm);
    Or(left:SearchTerm, right:SearchTerm);
}

enum SearchTermToken {
    Word(w : String);
    String(s : String);
    FMacroParam(s : String);
    OParent;
    CParent;
    OBracket;
    CBracket;
    OBox;
    CBox;
    FSlash;
    BSlash;
    Whitespace;
    And;
    Or;
    Not;
    Eq;
    Lt;
    Gt;
    Dollar;
    Circum;
    Tilde;
    Asterisk;
    Colon;
    Comma;
}

enum SearchTermConst {
    CString(s : String);
    CInt(i : Int);
    CFloat(n : Float);
    //CRaw
    CEReg(re : EReg);
    COReg(ore : String);
    CGlob(glob : GlobStar);
}
