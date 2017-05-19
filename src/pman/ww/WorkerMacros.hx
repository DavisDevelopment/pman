package pman.ww;

import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using tannus.macro.MacroTools;

class WorkerMacros {
    /**
      * add 'main' method to all subclasses of worker
      */
    public static macro function workerBuilder():Array<Field> {
        var lc = Context.getLocalClass().get();
        var ctp:TypePath = lc.fullName().toTypePath();
        var fields = Context.getBuildFields();
        fields.push({
            name: 'main',
            access: [Access.APublic, Access.AStatic],
            pos: Context.currentPos(),
            kind: FieldType.FFun({
                args: [],
                params: null,
                ret: null,
                expr: macro {
                    new $ctp().__start();
                }
            })
        });
        return fields;
    }
}
