package pman.tools;

import tannus.io.*;
import tannus.ds.*;

import hscript.*;
import hscript.Expr;

import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using hscript.Tools;

/*
   mixin class for working with hscript expressions
*/
class HsTools {

    /**
      * parse given String to an Expr
      */
    public static function expr(s:String, allowJSON:Bool=true, allowTypes:Bool=true):Expr {
        var p = new Parser();
        p.allowJSON = allowJSON;
        p.allowTypes = allowTypes;
        return p.parseString( s );
    }

    /**
      * convert Expr to a String
      */
    public static function toString(e : Expr):String {
        return Printer.toString( e );
    }

    public static function func(e:Expr, ?i:Interp):Dynamic {
        e = funce( e );
        if (!e.match(EFunction(_,_,_,_))) {
            throw 'Wtf??';
        }
        if (i == null)
            i = new Interp();
        var fun:Dynamic = i.expr( e );
        if (!Reflect.isFunction( fun )) {
            throw 'Wtf??';
        }
        return fun;
    }

    /**
      * create function expression from given expression
      */
    public static function funce(e : Expr):Expr {
        switch ( e ) {
            case EFunction(args, body, _, _):
                return e;

            case EBinop('=>', EIdent(name), body):
                return EFunction([{name:name}], makeReturn( body ), null, null);

            case EBinop('=>', EArrayDecl(argidents), body):
                var argnames:Array<String> = new Array();
                for (arge in argidents) switch ( arge ) {
                    case EIdent(arg_name):
                        argnames.push( arg_name );
                    default:
                        throw 'Unexpected $arge';
                }
                var args:Array<Argument> = argnames.map.fn(untyped {name: _});
                return EFunction(args, makeReturn( body ), null, null);

            default:
                var args:Array<Argument> = usArgList( e );
                return EFunction(args, makeReturn( e ));
        }
    }

    /**
      * build Array<Argument> by finding the '_'|'_[parameter index]' expressions
      */
    private static function usArgList(body : Expr):Array<Argument> {
        var _names:Array<String> = new Array();
        var _namePattern:RegEx = new RegEx(~/^_[1-9]*$/);
        body.iter(function(e) {
            switch ( e ) {
                case EIdent( name ) if (_namePattern.match( name )):
                    _names.push( name );

                default:
                    return ;
            }
        });
        _names = _names.unique();
        _names.sort(untyped Reflect.compare);
        if (_names.length == 0) {
            _names = ['_'];
        }
        //if (_names.length > 1) {
            //var nums = _names.map.fn(Std.parseInt(_.after('_')));
            //trace( nums );
        //}
        return _names.map(function(s):Argument {
            return {
                name: s
            };
        });
    }

    private static function makeReturn(e : Expr):Expr {
        if (!hasReturn( e )) {
            //TODO make smarter
            return EReturn( e );
        }
        else return e;
    }

    /**
      * iterate over/through [e], to determine whether it contains a return statement
      */
    public static function hasReturn(e : Expr):Bool {
        return search(e, function(ee : Expr) {
            return switch ( ee ) {
                case EReturn(_): true;
                case _: false;
            }
        });
    }

    public static function search(e:Expr, test:Expr->Bool):Bool {
        var status:Bool = false;
        function walker(ee : Expr):Void {
            if (!status && test( ee )) {
                status = true;
            }
        }
        e.iter( walker );
        return status;
    }

    /**
      * obtain a copy of [e], with all instances of [what] replaced with [with]
      */
    public static function replace(e:Expr, what:Expr, with:Expr):Expr {
        if (e.equals( what )) {
            return with;
        }
        else {
            return e.map(replacer.bind(_, what, with));
        }
    }

    // mapper method used by [replace]
    private static function replacer(e:Expr, what:Expr, with:Expr):Expr {
        if (e.equals( what )) {
            return with;
        }
        return e.map(replacer.bind(_, what, with));
    }


}
