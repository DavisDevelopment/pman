package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.graphics.Color;
import tannus.sys.*;
import tannus.TSys as Sys;
import tannus.async.*; 
import tannus.html.Win;
import tannus.html.Element;
import tannus.async.Promise;

#if renderer_process

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.core.engine.*;
import pman.db.AppDir;
import pman.edb.*;
import pman.edb.PManDatabase;
import pman.display.ColorScheme;
import pman.events.KeyboardControls;

#end

import js.html.Console;

import edis.Globals as Eg;
import tannus.math.TMath.*;
import edis.Globals.*;
import Slambda.fn;

import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.async.Asyncs;

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
      schedules [f] to be called [time_ms] milliseconds after 'createTimeout' is called
      NOTE: returns the function that cancels it
     **/
    public static function createTimout(time_ms:Int, f:Void->Void):Void->Void {
        var _id = window.setTimeout(f, time_ms);
        return window.clearTimeout.bind( _id );
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

    /*
       EXAMPLE:
       ----
       vsequence(function(add, done) {
          add(...);
          //...some interesting stuff
          done(<optional error argument>);
       });
    */
    public static function vsequence(builder:(VoidAsync->Void)->VoidCb->Void, done:VoidCb):Void {
        valist(builder, fn(_1.series(_2)), done);
    }

    public static function vbatch(builder:(VoidAsync->Void)->VoidCb->Void, done:VoidCb):Void {
        valist(builder, fn(_1.parallel(_2)), done);
    }

    /**
      * build and execute a list of VoidAsync tasks
      */
    public static function valist(builder:(VoidAsync->Void)->VoidCb->Void, executor:Array<VoidAsync>->VoidCb->Void, callback:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        function add(va: VoidAsync) {
            steps.push( va );
        }
        builder(add, function(?error) {
            if (error != null) {
                callback( error );
            }
            else {
                executor(steps, callback);
            }
        });
    }

    /**
      * convert the given synchronous function to an asynchronous one
      */
    public static inline function asyncify(f: Void->Void):VoidAsync {
        return (f.toAsync());
    }

    public static function promise<T>(x: PromiseResolution<T>):Promise<T> {
        return new Promise(function(yield, raise) {
            return Promise._settle(x, yield, raise);
        });
    }

    public static function promiseError<T>(x: Dynamic):Promise<T> {
        return new Promise(function(yield, raise) {
            return defer(function() raise( x ));
        });
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

    public static var global(get, never): Dynamic<Dynamic>;
    static inline function get_global() return js.Lib.global;

#if renderer_process

    public static var bpmain(get, never):BPlayerMain;
    private static inline function get_bpmain() return BPlayerMain.instance;

    public static var launchInfo(get, never):LaunchInfo;
    private static inline function get_launchInfo() return bpmain.launchInfo;

    public static var kbCtrl(get, never):KeyboardControls;
    private static inline function get_kbCtrl() return bpmain.keyboardControls;

    public static var player(get, never):Player;
    private static inline function get_player() return bpmain.player;

    public static var theme(get, never):ColorScheme;
    private static inline function get_theme() return player.theme;

    public static var database(get, never):PManDatabase;
    private static inline function get_database() return engine.db;

    public static var engine(get, never):Engine;
    private static inline function get_engine() return bpmain.engine;

    public static var exec(get, never):Executor;
    private static inline function get_exec() return engine.executor;

    public static var dialogs(get, never):Dialogs;
    private static inline function get_dialogs() return engine.dialogs;

    public static var appDir(get, never):AppDir;
    private static inline function get_appDir() return engine.appDir;

    //public static var preferences(get, never):Preferences;
    //private static inline function get_preferences() return database.preferences;

    public static var window(get, never):Win;
    private static inline function get_window() return Win.current;

    public static var console(get, never):Null<Console>;
    private static function get_console() {
        if (_c == null) {
            _c = [untyped {
            //return (untyped __js__('(typeof console !== "undefined")'));
                if (__strict_neq__(__typeof__(__js__('console')), "undefined")) {
                    __js__('console');
                }
                else {
                    null;
                }
            }];
        }
        return _c[0];
    }

    public static var us(get, never):Dynamic;
    private static inline function get_us() return Eg.us;

#end



    public static var platform(get, never):String;
    private static function get_platform():String {
        if (_platform == null)
            _platform = Sys.systemName();
        return _platform;
    }

    public static var osIsWindows(get, never): Bool;
    private static inline function get_osIsWindows() return (platform == 'Windows');

    public static var osIsLinux(get, never): Bool;
    private static inline function get_osIsLinux() return (platform == 'Linux');

    public static var osIsDarwin(get, never): Bool;
    private static inline function get_osIsDarwin() return (platform == 'Linux');

    public static var osIsNix(get, never): Bool;
    private static inline function get_osIsNix() return (osIsLinux || osIsDarwin);

/* === Variables === */

    private static var _platform : Null<String> = null;
    private static var _c: Null<Array<Null<Console>>> = null;
}
