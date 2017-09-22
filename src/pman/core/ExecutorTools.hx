package pman.core;

import Slambda.fn;
import haxe.Constraints.Function;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

import tannus.macro.MacroTools as Mt;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using tannus.async.VoidAsyncs;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using tannus.macro.MacroTools;

@:noPackageRestrict
class ExecutorTools {
    /**
      * macro-liciously add a MicroTask onto the Executor
      */
    public static macro function task(exec:ExprOf<Executor>, rest:Array<Expr>) {
        var async:Bool = false;
        var params:Array<Expr> = [];
        var taskExpr:Expr = rest.shift();

        switch ( taskExpr.expr ) {
            case EMeta(_.name => 'async', expr):
                async = true;
                params = parseOutParams(expr, rest, true);

            default:
                params = parseOutParams(taskExpr, rest, false);
        }

        var callExpr : Expr;
        if ( async ) {
            callExpr = macro ${exec}.asyncTask($a{params});
        }
        else {
            callExpr = macro ${exec}.syncTask($a{params});
        }
        return callExpr;
    }

#if macro

    /**
      * parse [e] and generate the Array<Expr> that will be used to create a new MicroTask
      */
    private static function parseOutParams(e:Expr, rest:Array<Expr>, async:Bool):Array<Expr> {
        var params:Array<Expr> = new Array();
        switch ( e.expr ) {
            case EConst(CIdent( name )):
                params = [e, macro null].concat( rest );
                

            case EField(ctxExpr, field):
                params = [e, ctxExpr].concat( rest );

            case ECall(funcExpr, args):
                switch ( funcExpr.expr ) {
                    //case EConst(CIdent(name)):
                        //params = [funcExpr, macro null, macro $a{args}];

                    case EField(ctxExpr, field):
                        params = [funcExpr, ctxExpr, macro $a{args}].concat( rest );

                    default:
                        params = [funcExpr, macro null, macro $a{args}].concat( rest );
                }

            case EBlock( _ ):
                if ( async ) {
                    var fbody:Expr = e.map(fbodyMapper.bind(_, macro next));
                    var fdecl:Expr = Mt.buildFunction(fbody, ['next']);
                    params = [fdecl, macro null].concat( rest );
                }
                else {
                    var fbody:Expr = e;
                    var fdecl:Expr = Mt.buildFunction(fbody, [], true);
                    params = [fdecl, macro null].concat( rest );
                }

            default:
                params = [e, macro null].concat( rest );
        }
        return params;
    }

    private static function fbodyMapper(e:Expr, callback:Expr):Expr {
        switch ( e.expr ) {
            case EContinue:
                return macro $callback( null );

            case EThrow( error ):
                error = error.map(fbodyMapper.bind(_, callback));
                return macro $callback($error);

            case EMeta(_.name=>'ignore', expr):
                return expr;

            default:
                return e.map(fbodyMapper.bind(_, callback));
        }
    }
#end
}

