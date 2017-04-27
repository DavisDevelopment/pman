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

    TDelimiter;
}

enum Word {
    Ident(id:String);
    String(s:String, del:Int);
    Ref(name:String);
}
