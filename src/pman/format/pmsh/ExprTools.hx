package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

import pman.format.pmsh.Expr;
import pman.format.pmsh.Token;
import pman.format.pmsh.NewParser;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using tannus.ds.SortingTools;
using tannus.FunctionTools;

class ExprTools {
    public static function getCommand(e: Expr):Null<CommandExpr> {
        return switch e {
            case ECommand(cmd): cmd;
            case EUnaryOperator(_, expr): getCommand(expr);
            case EBlock([ECommand(cmd)])|ERoot([ECommand(cmd)]): cmd;
            case _: null;
        };
    }

    public static function iter(e:Expr, f:Expr->Void):Void {
        switch e {
            case EBlock(body), ERoot(body):
                for (child in body)
                    f( child );

            case ECommand(cmd):
                for (param in cmd.parameters)
                    f( param );

            case EBinaryOperator(_, left, right):
                f( left );
                f( right );

            case EUnaryOperator(_, operand):
                f( operand );

            case EFunc(_, fe):
                f( fe );

            case EFor(_, a, b):
                f( a );
                f( b );

            case EWord(_),ESetVar(_,_):
                return ;
        }
    }

    public static function print(e:Expr):String {
        return Printer.format( e );
    }

    public static function map(e:Expr, f:Expr->Expr):Expr {
        return switch e {
            case EWord(word): EWord(word);
            case ESetVar(name, value): ESetVar(name, value);
            case EBlock(body): EBlock(body.map( f ));
            case ERoot(body): ERoot(body.map( f ));
            case ECommand({command:name, parameters:params}): ECommand(new CommandExpr(name, params.map( f )));
            case EBinaryOperator(op, left, right): EBinaryOperator(op, map(left, f), map(right, f));
            case EUnaryOperator(op, expr): EUnaryOperator(op, map(expr, f));
            case EFunc(name, expr): EFunc(name, map(expr, f));
            case EFor(id, iter, expr): EFor(id, map(iter, f), map(expr, f));
            //case _: e;
        };
    }

    public static function replace(e:Expr, what:Expr, repl:Expr):Expr {
        function mapper(expr:Expr):Expr {
            if (Type.enumEq(expr, e)) {
                return repl;
            }
            else return expr;
        }
        return map(e, mapper);
    }

    public static function wmap(e:Expr, f:Word->Word):Expr {
        function mapper(ee: Expr):Expr {
            return switch ee {
                case EWord(word): EWord(f(word));
                case ESetVar(name, value): ESetVar(f(name), f(value));
                //case ECommand(name, params): ECommand(f(name), params.map(p -> map(p, mapper)));
                case ECommand({command:name, parameters:params}): ECommand(new CommandExpr(f(name), params.map(p -> map(p, mapper))));
                case EBlock(body): EBlock(body.map(child -> map(child, mapper)));
                case ERoot(body): ERoot(body.map(child -> map(child, mapper)));
                case EBinaryOperator(op, left, right): EBinaryOperator(op, map(left, mapper), map(right, mapper));
                case EUnaryOperator(OpRedirectIo(IorIn(IoFile(desc))), value): EUnaryOperator(OpRedirectIo(IorIn(IoFile(f(desc)))), map(value, mapper));
                case EUnaryOperator(op, value): EUnaryOperator(op, map(value, mapper));

                case EFunc(name, body): EFunc(name, map(body, mapper));
                case EFor(id, iter, expr): EFor(id, map(iter, mapper), map(expr, mapper));
            };
        }
        return map(e, mapper);
    }

    public static function replaceWord(e:Expr, what:Word, repl:Word):Expr {
        function mapper(word: Word):Word {
            if (Type.enumEq(what, word)) {
                return repl;
            }
            else {
                return word;
            }
        }

        return wmap(e, mapper);
    }
}

class TokenTools {
    public static function tokenString(tk: Token):String {
        return switch tk {
            case Token.TDelimiter: ';';
            case Token.TEndOfInput: throw tk;
            case Token.TSym(s): s;
            case Token.TSpecial(c): c.aschar;
            case Token.TWord(w): (switch w {
                case Ident(id): id;
                case String(str, x): (function(q: String) {
                    return (q + str + q);
                })(['\'', '\"'][x]);
                case Ref(name): '$name';
                case Interpolate(expr): ExprTools.print(expr);
                case Substitution(type, name, expr): ExprTools.print( expr );
            });
        };
    }
}
