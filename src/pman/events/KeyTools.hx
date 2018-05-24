package pman.events;

import tannus.io.*;
import tannus.ds.*;
import tannus.events.Key;

import haxe.macro.Expr;
import haxe.macro.Context;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.ds.AnonTools;
using tannus.math.TMath;
#if macro
using haxe.macro.ExprTools;
using tannus.macro.MacroTools;
#end

class KeyTools {
    public static function toChar(key: Key):Null<Char> {
        return (switch key {
            case NumpadDot, Dot: '.';
            case NumpadForwardSlash, ForwardSlash: '/';
            case Enter: '\r'; 
            case Space: ' '; 
            case Backspace: cc(8);
            case Tab: cc(9);
            case NumpadPlus: '+';
            case OpenBracket: '[';
            case BaskSlash: '\\';
            case Minus: '-';
            case SemiColon: ';';
            case Comma: ',';
            case Delete: cc(226);
            case NumpadAsterisk: '*';
            case BackTick: cc(96);
            case letter if (letter.inRange(65, 90)): cc(letter);
            case number if (number.inRange(48, 57)): cc(number);
            case number if (number.inRange(96, 105)): cc(number - 48);
            case _: null;
        });
    }

    public static function fromChar(c: Char):Null<Key> {
        if (c.isAlphaNumeric()) {
            return c.
        }
    }

    static macro function cc(n: ExprOf<Int>):ExprOf<String> {
        switch ( n.expr ) {
            case EConst(CInt(Std.parseInt(_) => v)):
                return Context('"\\u${v.hex(4)}"', Context.currentPos());

            case _:
                return macro String.fromCharCode(${n});
        }
        //return Context.parseInlineString('\\u' + n.toString().lpad('0', 4));
    }
}
