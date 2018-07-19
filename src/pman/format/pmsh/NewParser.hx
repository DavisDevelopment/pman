package pman.format.pmsh;

import tannus.io.*;
import tannus.io.Byte;
import tannus.ds.*;
import tannus.ds.Maybe;

import pman.format.pmsh.Expr;
import pman.format.pmsh.Token;

import haxe.extern.EitherType as Either;
import haxe.io.Input;
import haxe.io.StringInput;
import haxe.ds.Option;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using tannus.ds.SortingTools;
using tannus.async.OptionTools;
using tannus.FunctionTools;
using pman.format.pmsh.ExprTools;

class NewParser {
    /* Constructor Function */
    public function new() {
        tkWordSymbols = '()[]:-+?';
        tkSpecialChars = [];
    }

/* === Instance Methods === */

    public static inline function run(i: Input):Expr {
        return (new NewParser().parse( i ));
    }

    public static inline function runString(s: String):Expr {
        return run(new StringInput( s ));
    }

    public function parseString(s: String):Expr {
        return parse(new StringInput( s ));
    }

    /**
      parse an AST from the given Input
     **/
    public function parse(i: Input):Expr {
        input = i;
        _index = 0;
        chars = new Array();
        tks = new Array();
        symbolsAreWords = true;

        var tk:Token, e:Expr, all:Array<Expr> = new Array();
        while ( true ) {
            tk = token();
            switch ( tk ) {
                case TEndOfInput:
                    break;

                default:
                    push( tk );
                    e = exprNext(expr());
                    all.push( e );
            }
        }
        
        return ERoot( all );
    }

    /**
      parse the next expression in the sequence
     **/
    function expr():Expr {
        var tk = token();
        switch tk {
            /* delimiter */
            case TDelimiter:
                return expr();

            /* command-looking word */
            case TWord(Ident(name)):
                var struct = parseStructure( name );
                if (struct != null) {
                    return struct;
                }
                else {
                    tk = token();
                    switch tk {
                        case TEndOfInput:
                            push( tk );
                            return ECommand(new CommandExpr(Ident(name), []));
                            //return ECommand(Ident(name), []);

                        case TDelimiter:
                            push( tk );
                            return ECommand(new CommandExpr(Ident(name), []));
                            //return ECommand(Ident(name), []);

                        case TSym('='):
                            return ESetVar(Ident(name), word());

                        case _:
                            push( tk );
                            push(TWord(Ident(name)));
                            return cmdExpr();
                    }
                }

            case TWord(word):
                return ECommand(new CommandExpr(word, cmdArgs()));
                //return ECommand(word, cmdArgs());

            case TSym('{'):
                push( tk );
                return blockExpr();

            case _:
                throw PmShError.EUnexpected( tk );
        }
    }

    function exprNext(e: Expr):Expr {
        var tk = token();
        switch tk {
            case TEndOfInput:
                push( tk );
                return e;

            case TSym('|'):
                return EBinaryOperator(OpPipe, e, fullExpr());

            case TSym('&'):
                tk = token();
                switch tk {
                    case TSym('>'):
                        return exprNext(EUnaryOperator(OpRedirectIo(IorOut(IoStdAll, readIoPort())), e));

                    case _:
                        push( tk );
                        push(TSym('&'));
                        return e;
                }

            case TSym('||'):
                return EBinaryOperator(OpOr, e, fullExpr());

            case TSym('&&'):
                return EBinaryOperator(OpAnd, e, fullExpr());

            case TSym('>'):
                push( tk );
                return exprNext(EUnaryOperator(OpRedirectIo(readIoRedirect()), e));

            case TSym('<'):
                push( tk );
                return exprNext(EUnaryOperator(OpRedirectIo(readIoRedirect()), e));

            case _:
                return e;
        }
    }

    function fullExpr():Expr {
        var e:Expr = exprNext(expr());
        return e;
    }

    function readIoRedirect():IoRedirect {
        var tk = token();
        switch tk {
            case TSym('>'):
                tk = token();
                switch tk {
                    case TSym('>'):
                        return IorOutAppend(IoStdOut, readIoPort());

                    case _:
                        push( tk );
                        return IorOut(IoStdOut, readIoPort());
                }

            case TSym('&'):
                tk = token();
                switch tk {
                    case TSym('>'):
                        return IorOut(IoStdAll, readIoPort());

                    case _:
                        push( tk );
                        throw EUnexpected(TSym('&'));
                }

            case TWord(Ident(id)|String(id,_)):
                var pattern:RegEx = new RegEx(~/([0-9&])([<>&]{1,2})(.+)/gmi);
                if (pattern.match( id )) {
                    var src:IoPortType = (switch pattern.matched(1) {
                        case '0': IoStdIn;
                        case '1': IoStdOut;
                        case '2': IoStdErr;
                        case '&': IoStdAll;
                        case other: IoFile(Ident(other));
                    }),
                    op:String = pattern.matched( 2 ),
                    sright:String = pattern.matched( 3 ).ifEmpty('').trim(),
                    dest:IoPortType = (switch sright {
                        case '': throw EMissingRightValue;
                        case '0' if (op.endsWith('&')): IoStdIn;
                        case '1' if (op.endsWith('&')): IoStdOut;
                        case '2' if (op.endsWith('&')): IoStdErr;
                        case other: IoFile(Ident( other ));
                    });

                    return switch op {
                        case '>', '>&': IorOut(src, dest);
                        case '>>': IorOutAppend(src, dest);
                        case '<': throw EUnexpected('<');
                        case _: throw EUnexpected(op);
                    };
                }
                else {
                    push( tk );
                    throw EUnexpected( tk );
                }

            case _:
                push( tk );
                throw EUnexpected( tk );
        }
    }

    /**
      read an IOPortType value
     **/
    function readIoPort():IoPortType {
        var tk = token();
        switch tk {
            case TSym('&'):
                tk = token();
                switch tk {
                    case TWord(Ident(id)) if (id.isNumeric()):
                        return switch id {
                            case '1': IoStdOut;
                            case '2': IoStdErr;
                            case _: throw EUnexpected( id );
                        };

                    case TWord(word):
                        return IoFile( word );

                    case _:
                        push( tk );
                        throw EUnexpected( tk );
                }

            case TWord(word):
                return IoFile( word );

            case _:
                throw EUnexpected( tk );
        }
    }

    /**
      parse out a command expression
     **/
    function cmdExpr():Expr {
        var tk = token();
        switch tk {
            case TWord(word):
                //return ECommand(word, cmdArgs());
                return ECommand(new CommandExpr(word, cmdArgs()));

            case _:
                throw EUnexpected( tk );
        }
    }

    /**
      parse out a block-level expression
     **/
    function blockExpr():Expr {
        var tk = token();
        switch tk {
            case TSym('{'):
                var body:Array<Expr> = [];
                while ( true ) {
                    tk = token();
                    switch tk {
                        case TEndOfInput:
                            throw PmShError.EUnterminatedBlock;

                        case TDelimiter:
                            continue;

                        case TSym('}'):
                            return EBlock(body);

                        case _:
                            push( tk );
                            body.push(expr());
                    }
                }

                return EBlock(body);

            case _:
                throw PmShError.EUnexpected(tk);
        }
    }

    /**
      parse out the next word-expression
     **/
    function wordExpr():Expr {
        var tk = token();
        switch tk {
            case TWord(word):
                return EWord( word );

            default:
                throw PmShError.EUnexpected( tk );
        }
    }

    function word():Word {
        var tk = token();
        return switch tk {
            case TWord(word): word;
            case _: throw EUnexpected(tk);
        };
    }

    /**
      parse out a list of command-arguments
     **/
    function cmdArgs():Array<Expr> {
        var args:Array<Expr> = new Array();
        while ( true ) {
            var tk = token();
            switch tk {
                case TDelimiter:
                    return args;

                case TSym(_), TEndOfInput:
                    push( tk );
                    return args;

                case TWord(word):
                    args.push(EWord(word));

                case _:
                    push( tk );
                    throw EUnexpected( tk );
            }
        }
        return args;
    }

    /**
      parse out a special structure
     **/
    function parseStructure(struct: String):Null<Expr> {
        switch struct {
            case 'function':
                var name:String,
                namere:RegEx = new RegEx(~/([A-Z_][A-Z0-9_]*)\(\)/gi),
                expr:Expr,
                tk:Token = token();
                switch tk {
                    case TWord(Ident(fid)) if (namere.match( fid )):
                        var l: String = namere.matchedLeft(),
                        r: String = namere.matchedRight(),
                        n: String = namere.matched(1);

                        if (l.hasContent()) {
                            throw EUnexpected('[$l]$n');
                        }
                        else if (r.hasContent()) {
                            throw EUnexpected('$n[$r]');
                        }
                        else {
                            name = n;
                            expr = fullExpr();
                            return EFunc(name, expr);
                        }

                    case _:
                        throw EUnexpected( tk );
                }

            case 'for':
                var name:String, iter:Expr, body:Expr;
                var tk = token();
                switch tk {
                    case TWord(Ident(id)):
                        name = id;
                        expectIdent(x -> (x == 'in'));
                        iter = expr();
                        maybeToken(TDelimiter);
                        expectIdent(x -> (x == 'do'));
                        body = fullExpr();
                        maybeToken(TDelimiter);
                        expectIdent(x -> (x == 'done'));
                        return EFor(name, iter, body);

                    case _:
                        throw EUnexpected( tk );
                }

            default:
                return null;
        }
    }

    /**
      get the next Token in the input buffer
     **/
    function token():Token {
        if (!tks.empty()) {
            return tks.shift();
        }
        else {
            var char:Byte = readChar();
            switch char {
                /* end of input */
                case 0:
                    return TEndOfInput;

                /* whitespace */
                case 9, 10, 13, 32:
                    if (char.isLineBreaking()) {
                        while ( true ) {
                            char = readChar();
                            if (!char.isWhiteSpace()) {
                                unshiftByte( char );
                                break;
                            }
                        }

                        return TDelimiter;
                    }
                    else {
                        return token();
                    }

                case _ if (tkSpecialChars.has( char )):
                    return TSpecial( char );

                /* strings */
                case "'".code, '"'.code:
                    var word = readStr(char);
                    return TWord(String(word, switch char {
                        case '\"'.code: 0;
                        case "\'".code: 1;
                        default: throw 'Unexpected $char';
                    }));

            
                /* & stuff */
                case '&'.code:
                    char = readChar();
                    switch char {
                        case '&'.code:
                            return TSym('&&');

                        case _:
                            unshiftByte( char );
                            return TSym('&');
                    }

                case '|'.code:
                    char = readChar();
                    switch char {
                        case '|'.code:
                            return TSym('||');

                        case _:
                            unshiftByte( char );
                            return TSym('|');
                    }

                case '>'.code:
                    return TSym('>');

                case '<'.code:
                    return TSym('<');

                case '{'.code:
                    return TSym('{');

                case '}'.code:
                    return TSym('}');

                case ';'.code:
                    return TDelimiter;

                /* equals sign */
                case '='.code:
                    return TSym('=');

                case '('.code if (!symbolsAreWords):
                    return TSym('(');

                case ')'.code if (!symbolsAreWords):
                    return TSym(')');

                case '['.code if (!symbolsAreWords):
                    return TSym('[');

                case ']'.code if (!symbolsAreWords):
                    return TSym(']');

                case '-'.code if (!symbolsAreWords):
                    return TSym('-');

                case '+'.code if (!symbolsAreWords):
                    return TSym('+');

                case ':'.code if (!symbolsAreWords):
                    return TSym(':');

                /* dollar sign */
                case "$".code:
                    var prevSaw = this.symbolsAreWords;
                    symbolsAreWords = false;
                    var t = token();
                    switch t {
                        case TWord(Ident(id)):
                            return TWord(Ref(id));

                        /* '(' | '{' */
                        case TSym('('):
                            var parent:Expr = readRegion('(', ')');
                            trace('' + parent);
                            return TWord(Interpolate(parent));

                        case _:
                            push( t );
                            return TSym("$");
                    }

                /* read out word tokens */
                case _:
                    if (isWordChar( char )) {
                        unshiftByte( char );
                        return TWord(Ident(readWord()));
                    }
                    else {
                        throw EUnexpected('"${char.aschar}"');
                    }
            }
        }
    }

    function readWord():String {
        var word:StringBuf = new StringBuf(),
        escaped:Bool = false,
        char:Byte;

        while ( true ) {
            char = readChar();

            if (char == 0) {
                unshiftByte( char );
                break;
            }
            else if (!escaped && char.equalsChar('\\')) {
                escaped = true;
                continue;
            }
            else if ( escaped ) {
                word.addChar( char );
            }
            else if (char.isWhiteSpace()) {
                unshiftByte( char );
                break;
            }
            else if (!isWordChar( char )) {
                unshiftByte( char );
                break;
            }
            else {
                word.addChar( char );
            }
        }

        return word.toString();
    }

    /**
      read a String from the input buffer
     **/
    function readStr(delimiter:Byte, ?escape:Byte):String {
        if (escape == null)
            escape = '\\'.code;
        var res:StringBuf = new StringBuf(),
        escaped:Bool = false;
        while ( true ) {
            var c = readChar();
            if (c == 0) {
                throw 'UnterminatedString';
            }
            else if ( escaped ) {
                res.addChar( c );
                escaped = false;
            }
            else if (!escaped && c == escape) {
                escaped = true;
            }
            else if (c == delimiter) {
                return res.toString();
            }
            else {
                res.addChar( c );
            }
        }
        return res.toString();
    }

    function readRegion(so:String, sc:String) {
        var o:Byte = so.byteAt(0), c:Byte = sc.byteAt(0);
        var scp = this.tkSpecialChars.copy();
        inline function restore() {
            this.tkSpecialChars = scp;
        }

        if (!tkSpecialChars.has( o ))
            tkSpecialChars.push( o );
        if (!tkSpecialChars.has( c ))
            tkSpecialChars.push( c );
        var t: Token;

        switch (t = token()) {
            case TSpecial(char) if (char == o || char == c):
                push( t );

            default:
                push( t );
                restore();
                throw EWhatTheFuck('Region(start=$so end=$sc) not present', t);
        }

        var b = new StringBuf(),
        level = 0,
        tokenTree = [],
        t: Token;

        while ( true ) {
            t = token();
            switch t {
                case TSpecial(special):
                    if (special == o) {
                        if (level > 0)
                            tokenTree.push( t );
                        ++level;
                    }
                    else if (special == c) {
                        if (level > 1)
                            tokenTree.push( t );
                        --level;
                        if (level == 0)
                            break;
                    }

                case TEndOfInput:
                    restore();
                    throw EWhatTheFuck('betty', t);

                case _:
                    tokenTree.push( t );
            }
        }

        for (ct in tokenTree)
            b.add(ct.tokenString());
        var ret = b.toString();
        restore();

        return runString( ret );
    }

    /**
      check whether the given Byte is a Word character
     **/
    function isWordChar(c:Byte):Bool {
        return !(c.isAny("$", ';', '=') || (symbolsAreWords ? false : isSymWordChar(c)));
    }
    function isSymWordChar(c: Byte):Bool {
        for (i in 0...tkWordSymbols.length)
            if (tkWordSymbols[i] == c)
                return true;
        return false;
    }

    /**
      betty
     **/
    inline function ignore(t: Token) {
        while ( true ) {
            var nt = token();
            if (!nt.equals( t )) {
                push( nt );
                break;
            }
        }
    }

    /**
      assert that the next token in the input will pass the given test
     **/
    function expect(test: Token->Bool):Token {
        var tk = token();
        if (test( tk )) {
            return tk;
        }
        else {
            push( tk );
            throw EUnexpected( tk );
        }
    }
    inline function expectToken(t: Token):Token {
        return expect(x -> Type.enumEq(t, x));
    }
    inline function expectWord(test: String->Bool):Token {
        return expect(function(tk: Token) {
            return switch tk {
                case TWord(Ident(s)|String(s,_)): test(s);
                case _: false;
            }
        });
    }
    inline function expectIdent(test: String->Bool):Token {
        return expect(function(tk: Token) {
            return switch tk {
                case TWord(Ident(id)): test( id );
                case _: false;
            }
        });
    }

    function maybe(test: Token->Bool):Bool {
        try {
            return (expect( test ) != null);
        }
        catch (error: PmShError) {
            if (error.match(EUnexpected(_))) {
                return false;
            }
            else {
                throw error;
            }
        }
    }

    function maybeToken(t: Token):Bool {
        return maybe(x -> Type.enumEq(x, t));
    }

    /**
      betty
     **/
    inline function push(t: Token) {
        if (tks == null)
            tks = [];
        tks.unshift( t );
    }

    /**
      read a character from the input buffer
     **/
    inline function readChar():Byte {
        if (chars != null && !chars.empty()) {
            return chars.shift();
        }
        else {
            return try input.readByte() catch (error: haxe.io.Eof) 0;
        }
    }

    /**
      push a Byte back onto the input buffer
     **/
    inline function unshiftByte(c: Byte) {
        if (chars == null)
            chars = [];
        if ((c : Int) >= 0)
            chars.unshift( c );
    }

/* === Instance Fields === */

    var originalInput: ByteArray;
    var input: Input;
    var _index: Int;

    var chars: Null<Array<Byte>>;
    var tks: Null<Array<Token>>;
    var symbolsAreWords: Bool;
    var tkWordSymbols: ByteArray;
    var tkSpecialChars: Array<Byte>;
}

/**
  Error types for PmBash
  TODO move this into its own module
 **/
enum PmShError {
    EUnexpected(x: Dynamic);
    EWhatTheFuck(q:String, v:Dynamic);
    ENameError(name:String, ?errorType:String);
    ECommandNotFound(name: Word);

    EUnterminatedString;
    EUnterminatedBlock;
    EMissingLeftValue;
    EMissingRightValue;
}
