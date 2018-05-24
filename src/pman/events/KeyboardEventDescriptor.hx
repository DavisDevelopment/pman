package pman.events;

import tannus.ds.*;
import tannus.io.*;
//import tannus.events.;
import tannus.events.Key;

import haxe.extern.EitherType;

import Std.*;
import tannus.math.TMath.*;

import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

//@:structInit
class KeyboardEventDescriptor implements IComparable<KeyboardEventDescriptor> {
    /* Constructor Function */
    public function new(key:Key, ?flags:Iterable<>):Void {
        this.key = key;
        this.alt = alt;
        this.ctrl = ctrl;
        this.shift = shift;
        this.meta = meta;
        hash = _hash( this );
    }

/* === Instance Methods === */

    /**
      check that [e] matches the description that [this] defines
      WAY more verbose than should be necessary
     **/
    public function test(e : KeyboardEvent):Bool {
        if ( !nonStandard ) {
            return (
                (key == e.key) &&
                (alt == e.altKey) &&
                (ctrl == e.ctrlKey) &&
                (shift == e.shiftKey) &&
                (meta == e.metaKey)
            );
        }
        else if (key == e.key) {
            // map of comparisons along all standard attributes
            var standard = [
                'key' => (key == e.key),
                'alt' => (alt == e.altKey),
                'ctrl' => (ctrl == e.ctrlKey),
                'shift' => (shift == e.shiftKey),
                'meta' => (meta == e.metaKey)
            ];

            // method to delete a named comparison if found to be irrelevant
            inline function irrelevant(name)
                standard.remove(name);

            if ( ctrlOrMeta ) {
                irrelevant('ctrl');
                irrelevant('meta');

                if (!(osIsWindows ? e.ctrl : e.meta)) {
                    return false;
                }
            }

            //... maybe more than just the one non-standard contingency at some point

            // now check all remaining relevant comparisons
            for (x in standard) {
                if (x == false)
                    return false;
            }
            return true;
        }
        else return false;
    }

    /**
      * clone [this]
      */
    public function clone():KeyboardEventDescriptor {
        return new KeyboardEventDescriptor(key, alt, ctrl, shift, meta);
    }

    /**
      * compare to other
      */
    public function compareTo(o : KeyboardEventDescriptor):Int {
        return Reflect.compare(hash, o.hash);
    }

    /**
      convert [this] to a human-readable form and return it
     **/
    public function toString():String {
        if (str == null)
            str = _str( this );
        return str;
    }

    /**
      * 
      */
    static function _hash(d: KeyboardEventDescriptor):String {
        inline function bc(b: Bool)
            return (b ? '1' : '0');

        return [
            (string( d.key ).lpad('0', 4)),
            bc( d.alt ), bc( d.ctrl ), bc( d.shift ), bc( d.meta ),
            //-- non-standard
            bc( d.ctrlOfMeta )
        ].join(',');
    }

    static function _str(d: KeyboardEventDescriptor):String {
        var chunks = [];
        inline function add(v)
            chunks.push( v );
        inline function addb(v, b:Bool)
            if ( b )
                add( v );

        addb(d.alt, 'Alt');
        addb(d.ctrl, 'Ctrl');
        addb(d.shift, 'Shift');
        addb(d.meta, 'Super');
        add( d.key.name );

        return chunks.join('+');
    }

    /**
      * get array of modifier values
      */
    public function mods():Array<Bool> {
        return [alt, ctrl, shift, meta];
    }

    /**
      build and return a KeyboardEventDescriptor from a KeyboardEvent
     **/
    public static function fromEvent(e : KeyboardEvent):KeyboardEventDescriptor {
        return new KeyboardEventDescriptor(e.key, e.altKey, e.ctrlKey, e.shiftKey, e.metaKey);
    }

    /**
      build and return a KeyboardEventDescriptor from a String
     **/
    public static function fromString(str: String):KeyboardEventDescriptor {
        var tokens:Array<String> = str.split('+').map.fn(_.toLowerCase());
        var key:Null<Key> = null,
        flags:Array<ModFlagDef> = [];

        for (tk in tokens) {
            if (tk.length == 1) {
                var c:Char = tk;
                if (c.isAlphaNumeric()) {
                    c.
                }
            }
        }
    }

    /**
      get a mod-flag, converting from other types if necessary
     **/
    static function _flag(flag: ModFlagDef):KEDModifierFlag {
        if ((flag is String)) {
            return _str2flag(cast flag);
        }
        else if ((flag is KEDModifierFlag)) {
            return cast flag;
        }
        else {
            throw '"$flag" is not a valid modifier flag';
        }
    }

    /**
      parse through a given set of mod-flags and maps their data onto the given KeyboardEventDescriptor
     **/
    static function _parseFlags(fli:Iterable<KEDModifierFlag>, d:KeyboardEventDescriptor):KeyboardEventDescriptor {
        var flags: Set<KEDModifierFlag>;
        if ((fli is tannus.ds.set.ISet<Dynamic>))
            flags = cast fli;
        else {
            flags = new Set();
            flags.pushMany( fli );
        }

        for (flag in flags) switch flag {
            case Alt:
                d.alt = true;
            case Ctrl:
                d.ctrl = true;
            case Shift:
                d.shift = true;
            case Meta:
                d.meta = true;

            /* Non-Standard Flags */

            case CtrlOrMeta:
                d.ctrlOrMeta = true;
                d.nonStandard = true;
        }

        return d;
    }

    /**
      convert a given String to a mod-flag
     **/
    static function _str2flag(id: String):KEDModifierFlag {
        switch (id.toLowerCase()) {
            case 'alt':
                return Alt;

            case 'ctrl', 'control':
                return Ctrl;

            case 'shift':
                return Shift;

            case 'meta', 'super', 'command', 'cmd':
                return Meta;

            case 'ctrlormeta', 'commandorcontrol':
                return CtrlOrMeta;

            default:
                /**
                   supports many possible notations for CtrlOrMeta, as well as vim-style <flag-name> notation
                   is implemented this way so that no complex RegExp checks
                   or parsing are even reached in most invokations of [_str2flag]
                 **/
                var cmdOrCtrl = ~/^(?:(?:Cmd|Command|Meta)or(?:Ctrl|Control))|(?:(?:Ctrl|Control)|(?:Cmd|Command|Meta))$/i,
                vimKeyNotation = ~/^<([\w\-\b]+)>$/i;
                if (cmdOrCtrl.match( id )) {
                    return CtrlOrMeta;
                }
                /* Vim-Style Notation */
                else if (vimKeyNotation.match( id )) {
                    // extract the <...> bit
                    var vks:String = vimKeyNotation.matched(1).trim();

                    // split into token list so that <C-[key]> and <press [x]> expressions might as some point be handled
                    var tokens = (~/(?:[\b\-]|\s+)/g).split( vks ).map.fn(_.toLowerCase());
                    switch ( tokens ) {
                        case ['ctrl']:
                            return Ctrl;

                        case ['alt']:
                            return Alt;

                        case ['shift']:
                            return Shift;
                        
                        case ['super'|'command'|'cmd'|'meta']:
                            return Meta;

                        /**
                          TODO:
                          explore idea of implementing something like the <Leader>... keybinding notation in vimscript
                         **/
                        case ['leader']:
                            throw '<Leader>* keybindings not (yet?) supported';

                        /* anything else, not supported */
                        default:
                            throw 'Unrecognized vim-style keybinding modifier <$vks>';
                    }
                }
        }
        throw '"$id" is not a valid keybinding modifier';
    }

/* === Computed Instance Fields === */

/* === Instance Fields === */

    public var key : Key;
    public var alt(default, null): Bool;
    public var ctrl(default, null): Bool;
    public var shift(default, null): Bool;
    public var meta(default, null): Bool;

    /* special-case flags */
    public var ctrlOrMeta(default, null): Bool;

    private var nonStandard: Bool = false;
    private var hash: String;
    private var str: Null<String> = null;
}

enum KEDModifierFlag {
/* Standard Flags */
    Alt;
    Ctrl;
    Shift;
    Meta;

/* Non-Standard Flags */

    /**
      means a platform-specific hotkey descriptor
      on Win32: Ctrl
      on Linux|Darwin: Meta
     **/
    CtrlOrMeta;
}

typedef ModFlagDef = EitherType<KEDModifierFlag, String>;
