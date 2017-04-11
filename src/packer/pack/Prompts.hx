package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.sys.*;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Prompts {
    /**
      * perform a prompt
      */
    public static function prompt(msg:String, cb:String->Void):Void {
        var p = new Prompt( msg );
        p.getLine( cb );
    }

    /**
      * prompt a user for String input
      */
    public static function string(o : PromptOptions<String>):Promise<String> {
        return Promise.create({
            prompt(o.text, function(s : String) {
                // if no input was provided
                if (s == null || s == '') {
                    if (o.defaultValue != null) {
                        return o.defaultValue;
                    }
                    else {
                        @forward string( o );
                    }
                }
                // if input fails validation
                else if (o.validate != null && !o.validate( s )) {
                    // ask for that input again
                    @forward string( o );
                }
                else {
                    return s;
                }
            });
        });
    }

    /**
      * prompt user for Bool input
      */
    public static function bool(o : PromptOptions<Bool>):BoolPromise {
        var so:PromptOptions<String> = {
            text: o.text
        };
        if (o.defaultValue != null) {
            so.defaultValue = (o.defaultValue ? 't' : 'f');
        }
        return Promise.create({
            var sp = string( so );
            sp.then(function(s : String) {
                var value:Bool = false;
                switch (s.toLowerCase()) {
                    case 't', 'y':
                        value = true;
                    case 'f', 'n':
                        value = false;
                    default:
                        @forward bool( o );
                        @ignore return ;
                }
                return value;
            });
        }).bool();
    }
}

typedef PromptOptions<T> = {
    text : String,
    ?defaultValue : T,
    ?validate : T->Bool
};
