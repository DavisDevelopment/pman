package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

enum Token {
    TWord(word : Word);
    TSym(symbol : String);
    // special contextual meaning
    TSpecial(char: Byte);

    TDelimiter;
    TEndOfInput;
}

enum Word {
    Ident(id:String);
    String(s:String, del:Int);
    Ref(name: String);
    Interpolate(expr: Expr);
    Substitution(type:SubstitutionType, name:String, value:Expr);
}

enum SubstitutionType {

}
