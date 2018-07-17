package pman.pmbash.args;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import pman.format.pmsh.Cmd.CmdArg;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using pman.bg.URITools;
using tannus.async.Asyncs;

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
        for (nn in _names_(n)) {
            flags.set(nn, (coerce != null ? FVCoerced(coerce) : FVAny));
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
      allow for multiple names to be declared as a single string
     **/
    function _names_(name: String):Array<String> {
        if (name.has(',')) {
            return name.split(',').map.fn(_.trim()).filter.fn(_.hasContent());
        }
        else {
            return [name];
        }
    }
    
    /**
      * declare a subcommand
      */
    public function sub(cmd:String, builder:DirectiveSpec->Void):DirectiveSpec {
        var names = _names_( cmd );

        var kid = new DirectiveSpec(names[0]);
        for (n in names)
            subs[n] = kid;
        builder( kid );
        return kid;
    }

    /**
      create a new subcommand and declare it's "main" function inline
     **/
    public function subExec(cmd:String, body:(dir:Directive, argv:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String, Dynamic>, callback:VoidCb)->Void):DirectiveSpec {
        return sub(cmd, function(_) {
            _.executor( body );
        });
    }

    /**
      * declare the help text
      */
    public function help(msg: String):DirectiveSpec {
        this.helpText = msg;
        return this;
    }

    /**
      declare the "main" function for [this] directive
     **/
    public function executor(f: (dir:Directive, argv:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String, Dynamic>, callback:VoidCb)->Void):DirectiveSpec {
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
    //?main: Directive->Array<String> -> Set<String> -> Dict<String, Dynamic> -> Void,
    ?main: (dir:Directive, argv:Array<CmdArg>, flags:Set<String>, kwargs:Dict<String, Dynamic>, callback:VoidCb)->Void,
    //?_args: Array<String> -> Void,
    ?_args: (argv: Array<CmdArg>)->Void,
    //?_flags: Set<String> -> Void,
    ?_flags: (flags: Set<String>)->Void,
    //?_kwargs: Dict<String, Dynamic> -> Void
    ?_kwargs: (kwargs:Dict<String, Dynamic>)->Void
};

