package pman.format.pmsh;

import tannus.io.*;
import tannus.ds.*;

import pman.format.pmsh.Expr;
import pman.format.pmsh.Token;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.ds.AnonTools;
using tannus.ds.SortingTools;
using tannus.FunctionTools;

class ExprTools {
    public static function iter(e:Expr, f:Expr->Void):Void {
        switch e {
            case EBlock(body):
                for (child in body)
                    f( child );

            case ECommand(_, params):
                for (param in params)
                    f( param );

            case _:
                return ;
        }
    }

    public static function map(e:Expr, f:Expr->Expr):Expr {
        return switch e {
            case EBlock(body): EBlock(body.map( f ));
            case ECommand(name, params): ECommand(name, params.map( f ));
            case _: e;
        };
    }

    public static function wmap(e:Expr, f:Word->Word):Expr {
        function mapper(ee: Expr):Expr {
            return switch ee {
                case EWord(word): EWord(f(word));
                case ESetVar(name, value): ESetVar(f(name), f(value));
                case ECommand(name, params): ECommand(f(name), params.map(p -> map(p, mapper)));
                case EBlock(body): EBlock(body.map(child -> map(child, mapper)));
            };
        }
        return map(e, mapper);
    }
}
