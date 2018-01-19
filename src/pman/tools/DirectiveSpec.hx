package pman.tools;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.TSys as Sys;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using pman.bg.URITools;

class DirectiveSpec {
    /* Constructor Function */
    public function new(name: String):Void {
        this.name = name;
        this.flags = new Dict();
        this.subs = new Dict();
        this.proto = {
            main: null,
            _args: null,
            _flags: null,
            _kwargs: null
        };
    }

/* === Instance Methods === */

    /**
      * accept flag of the given name
      */
    public function flag<T>(n:String, ?coerce:String->T):DirectiveSpec {
        if (n.has(',')) {
            for (n in n.split(',')) {
                flags.set(n.trim(), (coerce != null ? FVCoerced(coerce) : FVAny));
            }
        }
        else {
            flags.set(n, (coerce != null ? FVCoerced(coerce) : FVAny));
        }
        return this;
    }

    /**
      * accept a flag with a value
      */
    public function param(k:String, ?f:String->Dynamic):DirectiveSpec {
        return flag(k, untyped (f != null ? f : FunctionTools.identity));
    }

    /* type-specific param methods */
    public function paramInt(k:String):DirectiveSpec return param(k, Std.parseInt);
    public function paramFloat(k:String):DirectiveSpec return param(k, Std.parseFloat);
    
    /**
      * declare a subcommand
      */
    public function sub(cmd:String, builder:DirectiveSpec->Void):DirectiveSpec {
        var kid = new DirectiveSpec( cmd );
        subs[cmd] = kid;
        builder( kid );
        return this;
    }

    /**
      * declare the help text
      */
    public function help(msg: String):DirectiveSpec {
        this.helpText = msg;
        return this;
    }

    /**
      *
      */
    public function executor(f: Directive->Array<String>->Set<String>->Dict<String, Dynamic>->Void):DirectiveSpec {
        proto.main = f;
        return this;
    }

    /**
      * get the help text for [this]
      */
    public function getHelpMessage():String {
        if (helpText.hasContent()) {
            return helpText;
        }
        else {
            return 'foo';
        }
    }

    /**
      * convert [this] into a Directive object
      */
    public function toDirective():Directive {
        return new Directive( this );
    }

/* === Instance Fields === */

    // the name of the Directive
    public var name: String;
    public var helpText: Null<String> = null;

    // the boolean-flags and named arguments (options) that the Directive accepts
    public var flags: Dict<String, FlagValType>;

    // the subcommands that the Directive has
    public var subs: Dict<String, DirectiveSpec>;
    
    private var proto: DirectiveMethods;
}

enum FlagValType {
    FVAny;
    FVCoerced<T>(f: String -> T);
}

typedef DirectiveMethods = {
    ?main: Directive->Array<String> -> Set<String> -> Dict<String, Dynamic> -> Void,
    ?_args: Array<String> -> Void,
    ?_flags: Set<String> -> Void,
    ?_kwargs: Dict<String, Dynamic> -> Void
};

