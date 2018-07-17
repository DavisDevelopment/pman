package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

import pman.format.pmsh.Token;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

enum Expr {
    ECommand(name:Word, params:Array<Expr>);
    ESetVar(name:Word, value:Word);
    EWord(word : Word);

/* == Combinators == */

    EBinaryOperator(operator:Binop, left:Expr, right:Expr);
    EBlock(body : Array<Expr>);
}

enum Binop {
    OpAnd;
    OpOr;
}
