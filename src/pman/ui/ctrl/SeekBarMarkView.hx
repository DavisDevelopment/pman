package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.events.*;
import tannus.events.Key;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.*;

import electron.ext.*;
import electron.ext.Menu;
import electron.ext.MenuItem;

import pman.core.*;
import pman.media.*;
import pman.media.info.Mark;
import pman.media.info.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.ctrl.SeekBar;
import pman.async.SeekbarPreviewThumbnailLoader as ThumbLoader;

import tannus.math.TMath.*;
import gryffin.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class SeekBarMarkView {
    /* Constructor Function */
    public function new(b:SeekBar, ut:MarkViewType):Void {
        bar = b;
        //mark = m;
        type = ut;
        tooltip = new SeekBarMarkViewTooltip( this );
    }

/* === Instance Methods === */

    /**
      * get [this] Mark's playback progress
      */
    public inline function prog():Percent {
        return Percent.percent(time, bar.player.durationTime);
    }

    public function rect():Rectangle {
        var r = new Rectangle(0, 0, (0.7 * bar.h), (bar.h));
        r.centerX = (bar.x + prog().of( bar.w ));
        r.y = bar.y;
        return r;
    }

    @:access(pman.ui.ctrl.SeekBar)
    public inline function hotKey():Maybe<HotKey> {
        return ((SeekBar.HOTKEYS)[bar.markViews.indexOf(this)]);
    }

/* === Computed Instance Fields === */

    public var name(get, never):String;
    private function get_name() {
        switch ( type ) {
            case MTReal( mark ):
                switch ( mark.type ) {
                    case Named( n ):
                        return n;
                    default:
                        throw 'Error: MarkView can only be attached to Marks of the Named(_) type, not ${mark.type}';
                }

            default:
                throw 'Error: snapshot-implied moments of interest do not have names';
        }
    }

    public var time(get, never):Float;
    private function get_time():Float {
        return switch ( type ) {
            case MTReal(mark): mark.time;
            case MTImplied(item): item.getTime();
        };
    }

    public var mark(get, never):Maybe<Mark>;
    private function get_mark() {
        return switch ( type ) {
            case MTReal(m): m;
            default: null;
        };
    }

/* === Instance Fields === */

    public var bar : SeekBar;
    //public var mark : Mark;
    public var type : MarkViewType;
    public var tooltip : SeekBarMarkViewTooltip;
}

enum MarkViewType {
    MTReal(mark : Mark);
    MTImplied(item : BundleItem);
}
