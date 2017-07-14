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

@:access( pman.ui.ctrl.SeekBar )
class SeekBarMarkView {
    /* Constructor Function */
    public function new(b:SeekBar, ut:MarkViewType):Void {
        bar = b;
        //mark = m;
        type = ut;

        if (canNavigateTo()) {
            tooltip = new SeekBarMarkViewTooltip( this );
        }
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

    public inline function pos():Point {
        return new Point((bar.x + prog().of(bar.w)), bar.y);
    }

    @:access(pman.ui.ctrl.SeekBar)
    public function hotKey():Maybe<HotKey> {
        if (canNavigateTo()) {
            return ((SeekBar.HOTKEYS)[bar.navMarkViews.indexOf(this)]);
        }
        else return null;
    }

    /**
      * get the color with which [this] shall be displayed
      */
    public function getColor():Color {
        if (color == null) {
            switch ( type ) {
                case MTReal( mark ):
                    color = bar.getForegroundColor().darken( 35 );

                case MTSnapshot( time ):
                    color = bar.getForegroundColor().greyscale();
            }
        }
        return color;
    }

    /**
      * get the type of indicator that [this] view shall have on the seekbar
      */
    public function getIndicatorType():MarkViewIndicator {
        switch ( type ) {
            case MTReal(_):
                return MIBox(getColor());

            case MTSnapshot(_):
                return MIBar(getColor());
        }
    }

    /**
      * whether [this] mark view can be jumped to via the bookmark navigation interface
      */
    public function canNavigateTo():Bool {
        return type.match(MTReal(_));
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
            case MTSnapshot(t): t;
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

    private var color : Null<Color> = null;
}

enum MarkViewType {
    MTReal(mark : Mark);
    MTSnapshot(time : Float);
    //MTImplied(item : BundleItem);
}

enum MarkViewIndicator {
    MIBox(fill:Color);
    MIBar(color:Color);
}
