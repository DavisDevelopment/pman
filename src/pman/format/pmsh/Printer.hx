package pman.format.pmsh;

import tannus.io.*;
import tannus.io.Byte;
import tannus.ds.*;
import tannus.ds.Maybe;
import tannus.sys.Path;

import pman.format.pmsh.NewParser;
import pman.format.pmsh.Expr;
import pman.format.pmsh.Token;

import haxe.extern.EitherType as Either;
import haxe.ds.Option;

import Slambda.fn;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using tannus.ds.SortingTools;
using tannus.async.OptionTools;
using tannus.FunctionTools;

class Printer {
    /* Constructor Function */
    public function new(?buffer: StringBuf):Void {
        b = (buffer != null ? buffer : new StringBuf());
        pretty = false;
        indentLvl = 0;
        indentChar = ' ';
        copyIndent = true;
    }

/* === Instance Methods === */

    public static function format(e: Expr):String {
        return (new Printer().print( e ));
    }

    /**
      format the given Expr into a String that represents (as accurately as possible) the code that created the Expr
     **/
    public function print(e:Expr, pretty:Bool=true):String {
        this.pretty = pretty;
        expr( e );
        return b.toString();
    }

    /**
      format/print [e]
     **/
    function expr(e:Expr, end:Bool=false):Printer {
        switch e {
            case EWord(w):
                word( w );

            case Expr.ESetVar(nameWord, valueWord):
                newline().indent();
                word(nameWord);
                put('=');
                word(valueWord);
                if ( end )
                    put(';');

            case EUnaryOperator(OpRedirectIo(redir), operand):
                expr(operand, false);
                ioredir(redir);

            case EBinaryOperator(op, left, right):
                expr(left, false);
                put(' ');
                operator(op);
                put(' ');
                expr(right, false);

            case Expr.EBlock(body):
                indent();
                putln('{');
                ++indentLvl;

                for (e in body) {
                    indent();
                    expr(e, false);
                    putln(';');
                }

                --indentLvl;
                indent();
                putln('}');

            case Expr.ERoot(ast):
                for (e in ast) {
                    expr(e, true);
                    newline();
                }

            case Expr.ECommand(cmd):
                join([EWord(cmd.command)].concat(cmd.parameters), (e -> expr(e, false)), (() -> put(' ')));
                if (!cmd.io_redirects.empty()) {
                    join(cmd.io_redirects, fn(ioredir(_)), fn(put(' ')));
                }

            case Expr.EFunc(name, body):
                indent();
                put('function $name() ');
                expr(body, true);

            case Expr.EFor(id, iter, body):
                indent();
                put('for $id in ').expr(iter, false);
                put('; do ');
                expr(body, false);
                newline();
                indent();
                put('done;');
        }

        return this;
    }

    function join<T>(items:Iterable<T>, item:T->Void, separator:Void->Void) {
        var iter = items.iterator(), x:T;
        while (iter.hasNext()) {
            x = iter.next();
            item( x );
            if (iter.hasNext()) {
                separator();
            }
        }
    }

    function operator(op: Binop) {
        switch op {
            case OpAnd:
                put('&&');
            case OpOr:
                put('||');
            case OpPipe:
                put('|');
        }
    }

    function ioredir(re: IoRedirect) {
        switch ( re ) {
            case IoRedirect.IorOut(src, dest):
                ioport(src, 0);
                put('>');
                ioport(dest, 1);

            case IoRedirect.IorOutAppend(src, dest):
                ioport(src, 0);
                put('>>');
                ioport(dest, 1);

            case IoRedirect.IorIn(src):
                put('<');
                ioport(src, 0);
        }
    }

    function ioport(port:IoPortType, kind:Int=0) {
        switch port {
            case IoStdOut:
                put(['', '&1'][kind]);

            case IoStdErr:
                put(['2', '&2'][kind]);

            case IoStdAll:
                put(switch kind {
                    case 0: '&';
                    case _: throw EUnexpected(IoStdAll);
                });

            case IoFile(fdWord):
                if (kind != 1) {
                    throw EUnexpected(port);
                }
                else {
                    fileword(fdWord);
                }

            case IoStdIn:
                throw EWhatTheFuck('There is no reason for stdin (fd0) to ever be redirected TO, or referenced explicitly', port);
        }
    }

    function fileword(pw: Word) {
        switch pw {
            case Ident(p), String(p, _):
                var path:Path = Path.fromString(p).normalize();
                put(path.toString());

            default:
                word( pw );
        }
    }

    function word(w: Word) {
        switch w {
            case Ident(id):
                put( id );

            case String(raw, 0):
                put('"$raw"');

            case String(raw, 1):
                put('\'$raw\'');

            case Ref(name):
                put('$$$name');

            case Interpolate(e):
                put("$(").expr(e).put(")");

            case Substitution(type, name, value):
                put("${").put(name).substtype(type).expr(value).put('}');
        }
    }

    function substtype(type: SubstitutionType):Printer {
        return put(':');
    }

    function put(s: String):Printer {
        b.add( s );
        return this;
    }
    function putln(s: String):Printer {
        return put(s + '\n');
    }
    function newline():Printer return putln('');
    function indent():Printer return put(leading());

    function leading():String {
        if (indentLvl == 0) {
            return '';
        }
        else {
            return (indentChar.times( indentLvl ));
        }
    }

/* === Instance Fields === */

    var b: StringBuf;
    var pretty:Bool;
    var indentChar: String;
    var indentLvl: Int;
    var copyIndent: Bool;
}
