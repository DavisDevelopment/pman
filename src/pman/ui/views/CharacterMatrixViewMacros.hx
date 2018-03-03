package pman.ui.views;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using haxe.macro.ExprTools;
using tannus.macro.MacroTools;

class CharacterMatrixViewMacros {
    public static macro function nullSet<T>(dest:ExprOf<T>, value:Expr, rest:Array<Expr>) {
        var trans:Expr = (macro _);
        var defaultValue:Null<Expr> = null;
        var valueTest:Expr = (macro (_ != null));

        switch ( rest ) {
            case [dv]:
                defaultValue = dv;

            case [dv, t]:
                defaultValue = dv;
                trans = t;

            case [dv, t, test]:
                defaultValue = dv;
                trans = t;
                valueTest = test;

            default:
                null;
        }

        if (defaultValue != null && defaultValue.expr.match(EConst(CIdent('null')))) {
            defaultValue = null;
        }

        var valueVar:Bool = !value.expr.match(EConst(CIdent(_)));
        var origValue:Expr = value;

        var valueVarDecl:Expr = (macro null);
        if ( valueVar ) {
            valueVarDecl = {
                pos: Context.currentPos(),
                expr: ExprDef.EVars([{
                    name: 'vtmp',
                    expr: value,
                    type: null
                }])
            };
        }

        valueTest = valueTest.replace(macro _, (valueVar ? macro vtmp : value));
        var valueRef:Expr = (valueVar ? macro vtmp : value);
        //value = (defaultValue != null ? (macro ($valueTest ? ${trans.replace(macro _, (valueVar ? valueVarExpr : value))} : $defaultValue)) : trans.replace(macro _, (valueVar ? valueVarExpr : value)));
        value = {
            if (defaultValue != null) {
                macro {
                    if ( $valueTest ) {
                        ${trans.replace(macro _, valueRef)};
                    }
                    else {
                        $defaultValue;
                    }
                };
            }
            else {
                trans.replace(macro _, valueRef);
            }
        };
        valueRef = (valueVar ? macro vtmp : value);

        var result:Expr = macro {
            $valueVarDecl;
            $dest = $valueRef;
        };
        return result;
    }

    public static macro function nullOr(args: Array<Expr>) {
        if (args.length % 2 != 0) {
            args.push(macro null);
        }

	    function expr(e: ExprDef):Expr {
	        return {
	            pos: Context.currentPos(),
	            expr: e
	        };
        }

        function or(x:Expr, y:Expr):Expr {
            return macro (if ($x != null) $x else $y);
        }

	    function ors(i: Array<Expr>):Expr {
			//return expr(EBinop(Binop.OpBoolOr, i.shift(), (i.length >= 2 ? or( i ) : i.shift())));
			return or(i.shift(), (i.length >= 2 ? ors( i ) : i.shift()));
	    }

	    return ors( args );
    }

    public static macro function deltaSet<T>(x:ExprOf<T>, y:ExprOf<T>, whenChanging:Expr, rest:Array<Expr>) {
        var eqTest:Expr = (macro (_1 == _2));
        switch ( rest ) {
            case [test]:
                eqTest = test;

            case anythingElse:
                null;
        }

        var test:ExprOf<Bool> = (macro !$eqTest).replace(macro _1, x).replace(macro _2, y);
        return macro {
            var dif:Bool = (${test});
            $x = $y;
            if ( dif ) {
                $whenChanging;
            }
        };
    }

    public static macro function qm(v:Expr, whenValid:Expr, rest:Array<Expr>) {
        var test:Expr = (macro ($v != null));

        if (rest.length > 0) {
            test = rest.shift();
        }

        whenValid = whenValid.replace(macro _, v);

        return (macro {
            if ($test) {
                $whenValid;
            }
        });
    }

    /**
      * fancy macro-method used by [_assign]
      */
    public static macro function _a<T>(b:ExprOf<Bool>, x:ExprOf<T>, y:ExprOf<T>):ExprOf<Null<T>> {
        return macro ({
            if (!$b || ($b && $y != null)) {
                $x = $y;
            }
            else null;
        });
    }
}
