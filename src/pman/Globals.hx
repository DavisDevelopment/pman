package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.graphics.Color;
import tannus.sys.*;
import tannus.TSys as Sys;
import tannus.async.*; 
import tannus.html.Win;
import tannus.html.Element;

#if renderer_process

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.core.engine.*;
import pman.db.AppDir;
import pman.edb.*;
import pman.edb.PManDatabase;
import pman.display.ColorScheme;


#end

import js.html.Console;

import edis.Globals as Eg;
import tannus.math.TMath.*;
import edis.Globals.*;

import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class Globals {
/* === Functions === */

    /**
      * get the current timestamp
      */
    public static inline function now():Float {
        return Eg.now();
    }

    /**
      * invoke [f] after waiting [ms] milliseconds
      */
    public static inline function wait(ms:Int, f:Void->Void) {
        Eg.wait(ms, f);
    }

    /**
      * defer [f] to the next call stack
      */
    public static inline function defer(f : Void->Void):Void Eg.defer( f );

    /**
      * defer [f] using Window.requestAnimationFrame
      */
    public static function animFrame(frame : EitherType<Void->Void, Float->Void>):Void {
        window.requestAnimationFrame(untyped frame);
    }

    /**
      * measure the amount of time it took to execute [action]
      */
    public static function measureTimeCost(action : Void->Void):Float {
        var start = now();
        action();
        return (now() - start);
    }

    /**
      * measure the amount of time taken to execute [action] asynchronously
      */
    public static function measureTimeCostAsync(action:VoidAsync, done:Cb<Float>):Void {
        var start = now();
        action(function(?error) {
            done(error, (now() - start));
        });
    }

    /**
      * output an error to the console
      */
    public static inline function report(error : Dynamic):Void { return Eg.report( error ); }
    public static inline function echo<T>(msg: T):T return Eg.echo( msg );
    public static function warn<T>(msg: T):T {
        if (console != null)
            console.warn( msg );
        return msg;
    }

    public static inline function recalc(?label: String):Void {
        warn("RECALC" + (label != null ? ' ["$label"]' : ''));
    }

    public static inline function e(x : Dynamic):Element return new Element( x );

/* === Computed Variables === */

#if renderer_process

    public static var bpmain(get, never):BPlayerMain;
    private static inline function get_bpmain() return BPlayerMain.instance;

    public static var player(get, never):Player;
    private static inline function get_player() return bpmain.player;

    public static var theme(get, never):ColorScheme;
    private static inline function get_theme() return player.theme;

    public static var database(get, never):PManDatabase;
    private static inline function get_database() return bpmain.db;

    public static var engine(get, never):Engine;
    private static inline function get_engine() return bpmain.engine;

    public static var exec(get, never):Executor;
    private static inline function get_exec() return engine.executor;

    public static var dialogs(get, never):Dialogs;
    private static inline function get_dialogs() return engine.dialogs;

    public static var appDir(get, never):AppDir;
    private static inline function get_appDir() return bpmain.appDir;

    public static var preferences(get, never):Preferences;
    private static inline function get_preferences() return database.preferences;

    public static var window(get, never):Win;
    private static inline function get_window() return Win.current;

    public static var us(get, never):Dynamic;
    private static inline function get_us() return Eg.us;

#end

    public static var platform(get, never):String;
    private static function get_platform():String {
        if (_platform == null)
            _platform = Sys.systemName();
        return _platform;
    }

/* === Variables === */

    private static var _platform : Null<String> = null;
}
