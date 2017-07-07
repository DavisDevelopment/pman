package pman;

import tannus.io.*;
import tannus.ds.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.db.*;
import pman.display.ColorScheme;

import tannus.math.TMath.*;
import foundation.Tools.*;

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
        return Date.now().getTime();
    }

    public static inline function wait(ms:Int, f:Void->Void) {
        return js.Browser.window.setTimeout(f, ms);
    }

    public static inline function defer(f : Void->Void):Void {
        tannus.node.Node.process.nextTick( f );
    }

/* === Variables === */

    public static var bpmain(get, never):BPlayerMain;
    private static inline function get_bpmain() return BPlayerMain.instance;

    public static var player(get, never):Player;
    private static inline function get_player() return bpmain.player;

    public static var theme(get, never):ColorScheme;
    private static inline function get_theme() return player.theme;

    public static var database(get, never):PManDatabase;
    private static inline function get_database() return bpmain.db;

    public static var preferences(get, never):Preferences;
    private static inline function get_preferences() return database.preferences;
}
