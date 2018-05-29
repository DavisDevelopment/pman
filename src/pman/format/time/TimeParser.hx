package pman.format.time;

import tannus.ds.*;
import tannus.io.*;
//import tannus.media.Duration;
import tannus.async.*;
import tannus.events.*;
import tannus.events.Key;
import tannus.math.Time;
import tannus.math.Percent;

import pman.core.*;
import pman.Globals.*;
import pman.format.time.TimeExpr;

import Std.*;
import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;
using tannus.FunctionTools;
using tannus.ds.AnonTools;

/**
  parses out the semi-grammar for time-jumps
 **/
class TimeParser {
    /* Constructor Function */
    public function new() {
        //
    }

/* === Instance Methods === */

    public static function run(s: String):Null<TimeExpr> {
        return (new TimeParser().parseString( s ));
    }

    public function parseString(s: String):Null<TimeExpr> {
        return parse(new haxe.io.StringInput( s ));
    }

    /**
      parse a TimeExpr from the given Input
     **/
    public function parse(i: haxe.io.Input):Null<TimeExpr> {
        this.i = i;
        tokens = [];

        var expr: Null<TimeExpr> = null;
        while ( true ) {
            var tk = token();
            if (tk == TEoi)
                break;
            push( tk );
            expr = parseExpr();
            if (expr != null)
                break;
        }

        return expr;
    }

    /**
      parse out an Expression
     **/
    function parseExpr():TimeExpr {
        var tk = token();
        switch ( tk ) {
            case TNumber(num):
                push( tk );
                return parseTimeExpr();

            case TOp(Plus):
                return ERel(Plus, parseTimeExpr());

            case TOp(Minus):
                return ERel(Minus, parseTimeExpr());

            case _:
                return null;
        }
    }

    /**
      parse an Expr that represents a specific Time
     **/
    function parseTimeExpr(?time:Time, ?num:Float, i:Int=0):TimeExpr {
        inline function etime():Time {
            if (time == null)
                time = new Time();
            return time;
        }

        var tk = token();
        trace(tk + '');
        switch ( tk ) {
            // End of Input
            case TEoi:
                if (time == null) {
                    unexpected(tk);
                }
                return ETime( time );

            // Another Number
            case TNumber(num):
                return parseTimeExpr(null, num);

            // the "%" operator
            case TOp(Perc) if (num != null):
                return EPercent(new Percent(num));

            // time-unit name/abbreviation identifiers
            case TIdent( id ) if (num != null):
                id = id.toLowerCase();
                time = etime();
                switch ( id ) {
                    /* seconds */
                    case 's', 'sec', 'second', 'seconds':
                        time.totalSeconds += num;
                        return parseTimeExpr(time);

                    /* minutes */
                    case 'm', 'min', 'minute', 'minutes':
                        time.totalSeconds += (num * 60.0);
                        return parseTimeExpr(time);

                    /* hours */
                    case 'h', 'hr', 'hour', 'hours':
                        time.totalSeconds += (num * 60.0 * 60.0);
                        return parseTimeExpr(time);

                    /* days */
                    case 'd', 'day', 'days':
                        time.totalSeconds += (num * 60.0 * 60.0 * 24.0);
                        return parseTimeExpr(time);

                    case _:
                        push( tk );
                        return ETime(time);
                }

            case TDoubleDot if (num != null):
                push( tk );
                var nums = parseColonTuple([num]);
                trace(nums+'');
                switch nums {
                    case [d, h, m, s]:
                        time = new Time(s, int(m), int(h), int(d));

                    case [h, m, s]:
                        time = new Time(s, int(m), int(h));

                    case [m, s]:
                        time = new Time(s, int(m));

                    default:
                        unexpected( tk );
                }
                trace(time+'');
                return ETime(time);

            case _:
                trace('' + tk);
                return null;
        }
    }

    /**
      parse out a tuple of numbers separated by a ':' (TDoubleDot)
     **/
    function parseColonTuple(a: Array<Float>):Array<Float> {
        var tk = token();
        switch tk {
            case TEoi:
                return a;

            case TDoubleDot:
                tk = token();
                switch tk {
                    case TNumber(num):
                        a.push( num );
                        return parseColonTuple( a );

                    case _:
                        unexpected( tk );
                }

            case _:
                push( tk );
                return a;
        }
        return a;
    }

    /**
      obtain the next Token in the input
     **/
    function token():TimeToken {
        if (!tokens.empty())
            return tokens.shift();

        var c: Byte;
        if (char < 0) {
            c = readByte();
        }
        else {
            c = this.char;
            this.char = -1;
        }

        while ( true ) {
            switch ( c ) {
                // null
                case 0:
                    return TEoi;
                // whitespace
                case 9, 10, 13, 32:
                    //

                // 0...9
                case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
                    var n = (c - 48) * 1.0;
                    var exp = 0;
                    while ( true ) {
                        c = readByte();
                        exp *= 10;
                        switch c {
                            case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
                                n = n * 10 + (c - 48);

                            case '.'.code:
                                if (exp > 0) {
                                    invalidChar( c );
                                }
                                exp = 1;

                            case _:
                                this.char = c;
                                return TNumber(exp > 0 ? (n * 10 / exp) : n);
                        }
                    }

                case '+'.code:
                    return TOp(Plus);

                case '-'.code:
                    return TOp(Minus);

                case '%'.code:
                    return TOp(Perc);

                case ':'.code:
                    return TDoubleDot;
                
                case _:
                    if (c.isLetter()) {
                        var id = String.fromCharCode( c );
                        while ( true ) {
                            c = readByte();
                            if (!c.isAlphaNumeric()) {
                                this.char = c;
                                return TIdent( id );
                            }

                            id += c;
                        }
                    }
                    invalidChar( c );
            }
        }
        return null;
    }

    function readByte():Byte {
        return try i.readByte() catch (e: Dynamic) 0;
    }

    function push(t) {
        tokens.push( t );
    }

    function maybe(tk) {
        var t = token();
        if (Type.enumEq(tk, t))
            return true;
        push( t );
        return false;
    }

    /*
    function nmaybe(tk) {
        var t = token();
        if (!Type.enumEq(tk, t))
            return true;
        push( t );
        return false;
    }
    */

    function invalidChar(char:Byte) {
        throw EInvalidChar(char, posInfos);
    }

    function unexpected(tk, ?pos:haxe.PosInfos) {
        throw EUnexpected(tokenString(tk), pos);
    }

    function unexEoi(?pos: haxe.PosInfos) {
        unexpected(TEoi, pos);
    }

    function error(e: TimeError) {
        throw e;
    }

    function tokenString(tk:TimeToken):String {
        return switch ( tk ) {
            case TEoi: '<EndOfInput>';
            case TDoubleDot: ':';
            case TOp(op): switch op {
                case Plus: '+';
                case Minus: '-';
                case Perc: '%';
            }
            case TNumber(num): ('' + num);
            case TIdent(id): id;
        };
    }

    /**
      convert the PosInfos string into a human-readable form
     **/
    function posInfosString():String {
        // iclassName, fileName, methodName, lineNumber
        inline function s(x:Dynamic):String return Std.string(x);
        return posInfos
        .owith([
            s(fileName), ':', s(lineNumber), ':',
            ' (in ', s(className), '.', s(methodName), ')'
        ]).join('');
    }

/* === Computed Instance Fields === */
/* === Instance Fields === */

    var i: haxe.io.Input;
    var tokens: Array<TimeToken>;
    var char: Int = -1;
    var posInfos: haxe.PosInfos;
}

enum TimeToken {
    TOp(op: TimeOp);
    //TUnit(u: TimeUnit);
    TDoubleDot;
    TNumber(n: Float);
    TIdent(id: String);
    TEoi;
}

