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
    EWord(word : Word);
    ECommand(command: CommandExpr);
    ESetVar(name:Word, value:Word);

    EFunc(name:String, body:Expr);
    EFor(ident:String, iter:Expr, body:Expr);

/* == Combinators == */

    EBinaryOperator(operator:Binop, left:Expr, right:Expr);
    EUnaryOperator(operator:Unop, e:Expr);

    EBlock(body : Array<Expr>);
    ERoot(ast: Array<Expr>);
}

enum Binop {
    OpAnd;
    OpOr;
    OpPipe;
}

enum Unop {
    OpRedirectIo(r: IoRedirect);
}

enum IoRedirect {
    IorOut(src:IoPortType, dest:IoPortType);
    IorOutAppend(src:IoPortType, dest:IoPortType);

    IorIn(src: IoPortType);
}

enum IoPortType {
    /* stdin */
    IoStdIn;

    /* stdout */
    IoStdOut;

    /* stderr */
    IoStdErr;

    /* both stdout and stderr */
    IoStdAll;

    /* file descriptor */
    IoFile(descriptor: Word);
}

class CommandExpr {
    public var command(default, null): Word;
    public var parameters(default, null): Array<Expr>;
    public var io_redirects(default, null): Array<IoRedirect>;

    public inline function new(c:Word, argv:Array<Expr>, ?redir:Array<IoRedirect>) {
        this.command = c;
        this.parameters = argv;
        this.io_redirects = (redir != null ? redir : []);
    }
}

enum EValue<T> {
    EvNil;
    EvUntyped(value: T):EValue<T>;
    EvBool(b: Bool):EValue<Bool>;
    EvNumber(n: Float):EValue<Float>;
    EvString(s: String):EValue<String>;
    EvArray<Item>(a: Array<EValue<Item>>):EValue<Array<Item>>;
    //EvInt(i: Int):EValue<Int>;
    //EvFloat(n: Float):EValue<Float>;
    //EvBytes(b: ByteArray):EValue<ByteArray>;
    //EvSMap<V>(sm: Map<String, V>):EValue<Map<String, V>>;
    //EvIMap<V>(im: Map<Int, V>):EValue<Map<Int, V>>;
}
