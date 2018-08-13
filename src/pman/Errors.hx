package pman;

import tannus.ds.Lazy;

import haxe.PosInfos;
import haxe.CallStack;

import haxe.macro.Expr;
import haxe.macro.Context;

#if (js && !macro)
import js.Error as NativeErrorBase;
#end

using StringTools;
using tannus.ds.StringUtils;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using tannus.macro.MacroTools;

class Errors {
	public static macro function ni(args: Array<Expr>):ExprOf<NotImplementedError> {
	    var ret:Expr = macro new pman.Errors.NotImplementedError(_a_, _b_);
	    switch args {
            case []:
                var name:Expr = macro $v{Context.getLocalMethod()};
                ret = ret.replace(macro _a_, name);
                ret = ret.replace(macro _b_, macro null);

            case [macro $name]:
                ret = ret.replace(macro _a_, name);
                ret = ret.replace(macro _b_, macro null);

            case [macro $name, macro $message]:
                ret = ret.replace(macro _a_, name);
                ret = ret.replace(macro _b_, message);

            case _:
                Context.error('Invalid arguments for pman.Errors.ni($args)', Context.currentPos());
	    }

		return macro ({
		    var r323:pman.Errors.NotImplementedError = $ret;
		    throw r323;
		    r323;
        });
	}

	public static macro function nullCheckFailed<T>(val:ExprOf<Null<T>>, rest:Array<Expr>) {
	    var lm = Context.getLocalMethod();
	    var lc = Context.getLocalModule();

	    var ename:Expr = cast {
	        expr: EConst(CString(val.toString())),
	        pos: Context.currentPos()
	    };
	    ename = macro ([$ename][0]);

	    var firstTwo = [val];
	    if (rest.length > 0)
	        firstTwo.push(rest.shift());

	    switch firstTwo {
            case [{expr:EConst(CIdent(name))}]:
                ename = macro $v{name};

            case [{expr:EConst(CIdent(_))}, nameExpr={expr:EConst(CIdent(name))}], [nameExpr={expr:EConst(CIdent(name))}, _], [_, nameExpr={expr:EConst(CIdent(name))}]:
                ename = macro $v{name};

            case _:
                null;
	    }

	    var ret:Expr = macro new pman.Errors.NullError($ename);
	    return macro $ret;
	}

	public static inline function wtf(?msg:Lazy<String>, ?type:String, ?code:Int, ?pos:PosInfos):Error {
	    return new WTFError(msg, type, code, pos);
	}

    @:noUsing
    public static inline function make(?type:String, ?code:Int, ?pos:PosInfos):Error {
        return new Error(type, code, pos);
    }

    public static inline function toNativeError(e: Error):NativeErrorBase {
        return new NativizedError( e );
    }

    #if (js && !macro)
    public static inline function hxeUnwrap(error: Dynamic):Dynamic {
        return
            if (Std.is(error, Type.resolveClass('js._Boot.HaxeError')))
                untyped (error.val : Dynamic);
            else error;
    }
    #else
    public static inline function hxeUnwrap(error: Dynamic):Dynamic {
        return error;
    }
    #end

    public static function pmeWrap(error: Dynamic):Error {
        error = [hxeUnwrap( error )][0];
        if (Std.is(error, Error))
            return cast(error, Error);
        else if (Std.is(error, NativeErrorBase)) {
            if (Std.is(error, NativizedError))
                return pmeWrap(((error: NativizedError<Dynamic>).originalError : Dynamic));
            else
                return new WrappedNativeError(cast error);
        }
        else {
            return new ErrorWrapper( error );
        }
    }
}

class Error {
    /* Constructor Function */
    public function new(type = 'Error', code = -1, ?pos:haxe.PosInfos) {
        this.type = ('' + type);
        this.code = code;
        this.location = pos;
    }

/* === Instance Methods === */

    /**
      convert [this] to a readable-String
     **/
    public function toString():String {
        return '$type: $message';
    }

    /**
      get the position-info for [this] Error
     **/
    public function position():PosInfos {
        return location;
    }

    /**
      specific position-info
     **/
    public inline function fileName():String return position().fileName;
    public inline function className():String return position().className;
    public inline function methodName():String return position().methodName;
    public inline function lineNumber():Int return position().lineNumber;

    /**
      get the exception-stack for [this] Error
     **/
    public inline function stack():Array<StackItem> {
        return CallStack.exceptionStack();
    }

/* === Computed Instance Fields === */

    public var stackMessage(get, null): String;
    function get_stackMessage():String {
        if (stackMessage == null) {
            stackMessage = CallStack.toString(stack());
        }
        return stackMessage;
    }

/* === Instance Fields === */

    public var type(default, null): String;
    public var code(default, null): Int;
    public var message(default, null): Lazy<String>;

    var location(default, null): haxe.PosInfos;
}

/**
  Error class for failed null-checks
 **/
class NullError<T> extends Error {
    /* Constructor Function */
    public function new(name='value', ?msg, type='NullError', code=1, ?pos:PosInfos) {
        super(type, code, pos);
        if (msg != null)
            message = msg;
        else {
            var methLoc:Lazy<String> = (() -> (className() + '.' + methodName()));
            var codeLoc:Lazy<String> = (() -> (fileName() + ':' + lineNumber()));
            message = (function() {
                return ([
                    Lazy.ofConst('null-value given for non-nullable $name in'),
                    methLoc,
                    '(', codeLoc, ')'
                ]:Array<Lazy<String>>).map(l -> l.get()).join(' ');
            });
        }
    }
}

/**
  error to throw when what should be impossible has happened
 **/
class WTFError extends Error {
    /* Constructor Function */
    public function new(?msg, type='WTFError', code=666, ?pos:PosInfos) {
        super(type, code, pos);
        if (msg != null)
            message = msg;
        else
            message = (() -> '');
    }

    override function toString():String {
        return (
            '$type' + 
            (if (code != 666) '($code)' else '') + ': ' + 
            (if (message != null && message.get().hasContent()) message.get() else 'Y Tho')
        );
    }
}

class ValueError<T> extends Error {
    /* Constructor Function */
    public function new(v, ?msg, type='ValueError', ?code, ?pos:PosInfos) {
        super(type, code, pos);

        data = v;
        if (msg != null)
            message = msg;
        else
            message = Std.string( data );
    }

    public var data(default, null): T;
}

class WrappedNativeError<E:NativeErrorBase> extends ValueError<E> {
    /* Constructor Function */
    public function new(err: E, ?pos:PosInfos) {
        super(err, err.message, err.name, -2, pos);
    }
}

class ErrorWrapper<T> extends ValueError<T> {}

class NotImplementedError extends ValueError<String> {
    /* Constructor Function */
    public function new(?name:String, ?msg, type='NotImplementedError', ?pos:PosInfos) {
        super('', msg, type, 0, pos);
        data = name.hasContent() ? name : methodName();
    }
}

class NativizedError <E:Error> extends NativeErrorBase {
    /* Constructor Function */
    public function new(err: E) {
        super( err.message );
        name = err.type;
        originalError = err;
    }

/* === Methods === */

/* === Fields === */

    public var originalError(default, null): E;
}

#if macro
class NativeErrorBase {
    public var message(default, null): String;
    public var name(default, null): String;

    /* Constructor Function */
    public function new(x) {
        name = 'Error';
        message = x;
    }
}
#end
