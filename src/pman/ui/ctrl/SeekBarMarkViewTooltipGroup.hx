package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.math.Time;
import tannus.events.*;
import tannus.events.Key;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.*;
import gryffin.ui.Border;

import electron.ext.*;
import electron.ext.Menu;
import electron.ext.MenuItem;

import pman.core.*;
import pman.media.*;
import pman.media.info.Mark;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.hud.*;
import pman.ui.ctrl.*;
import pman.ui.ctrl.SeekBar;
import pman.async.SeekbarPreviewThumbnailLoader as ThumbLoader;

import motion.Actuate;

import tannus.math.TMath.*;
import gryffin.Tools.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.TMath;
using tannus.FunctionTools;

@:access( pman.ui.ctrl.SeekBarMarkViewTooltipPanel )
class SeekBarMarkViewTooltipGroup extends Ent {
    /* Constructor Function */
    public function new(panel:SeekBarMarkViewTooltipPanel, firstWord:String, ?members:Array<SeekBarMarkViewTooltip>) {
        super();

        this.panel = panel;
        this.word = firstWord;
        this.name = (word + '...');
        this.members = new Array();
        if (members != null) {
            for (x in members) {
                this.members.push( x );
            }
        }

        tb = [new TextBox(), new TextBox(), new TextBox()];
        tbr = [new Rect(), new Rect(), new Rect()];
        border = new Border(3.0, player.theme.primary.lighten( 20 ), 3.0);
    }

/* === Instance Methods === */

    /**
      * 'open' [this] group, revealing all sub-marks to
      */
    public function open():Void {
        for (m in members) {
            m.show();
        }

        positionTips();

        this.opened = true;
        dispatch('opened', this);
    }

    /**
      * close [this] group
      */
    public function close():Void {
        for (m in members) {
            m.hide();
        }
        this.opened = false;
        dispatch('closed', this);
    }

    /**
      * perform per-frame logic
      */
    override function update(stage: Stage):Void {
        super.update( stage );

        // get info
        var colors = getColors();
        var key = getHotKey();

        if (members.length == 1) {
            name = members[0].markView.name;
        }
        else {
            name = (word + ' ...');
        }

        // update state
        _update(colors, key);
        calculateGeometry(cast stage.rect);
    }

    /**
      * render [this] group
      */
    override function render(stage:Stage, c:Ctx):Void {
        if (!panel.hasOpenTooltipGroup()) {
            if (opacity != 1.0) {
                c.save();
                c.globalAlpha = opacity;
            }

            if (ttr == null) {
                calculateGeometry( rect );
            }

            var colors = getColors();

            // draw background
            c.beginPath();
            c.fillStyle = colors[1];
            c.drawRoundRect(rect, 3.0);
            c.closePath();
            c.fill();

            // draw border
            c.beginPath();
            c.strokeStyle = border.color;
            c.lineWidth = border.width;
            c.drawRoundRect(rect, border.radius);
            c.closePath();
            c.stroke();

            // draw textual data
            for (index in 0...tb.length) {
                var t = tb[index];
                var r = tbr[index];
                c.drawComponent(t, 0, 0, t.width, t.height, r.x, r.y, r.w, r.h);
            }

            if (opacity != 1.0) {
                c.restore();
            }
        }

        //super.render(stage, c);
        if (members.length > 2) {
            for (t in members) {
                if (!t._hidden && shouldChildRender(cast t)) {
                    t.render(stage, c);
                }
            }
        }
    }

    /**
      * get the colors used by [this]
      */
    private function getColors():Array<Color> {
        if (colors == null) {
            var cols = new Array();
            cols.push(new Color(255, 255, 255));
            cols.push( player.theme.primary );
            colors = cols.map( player.theme.save );
            return cols;
        }
        else {
            return colors.map( player.theme.restore );
        }
    }

    /**
      * do the stuff
      */
    private function _update(colors:Array<Color>, ?k:Null<HotKey>):Void {
        // first text box
        var t:TextBox = tb[0];
        t.text = name;
        t.bold = true;
        t.fontSize = 12;
        t.color = colors[0];
        // second text box
        t = tb[1];
        //t.text = (members.length'${members.length} item${members.length > 1 ? "s" : ""}';
        if (members.length == 1) {
            t.text = Std.string(new Time(members[0].markView.mark.time));
        }
        else {
            t.text = (members.length + ' items');
        }

        t.fontSize = 8.5;
        t.color = new Color(255, 255, 255);
        // third text box
        t = tb[2];
        var char:String = '';
        if (k != null) {
            char = k.char.aschar.toLowerCase();
            if ( k.shift ) {
                char = char.toUpperCase();
            }
        }
        t.text = ('($char)');
        t.color = player.theme.secondary;
        t.fontSize = 10.0;
        // -- 
        ttr = new Rect();
        for (t in tb) {
            t.fontSizeUnit = 'px';
            ttr.width = max(ttr.width, t.width);
            ttr.height += t.height;
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r: Rect<Float>):Void {
        inline function dbl(x:Float):Float return (x * 2);
        inline function reset(r: Rect<Float>) r.x = r.y = r.w = r.h = 0.0;

        // set content rectangle
        w = (ttr.width + dbl( margin ));
        h = (ttr.height + margin);

        //tbr = new Array();
        var yy:Float = (y + margin);
        var t:TextBox, r:Rect<Float>;
        for (index in 0...tb.length) {
            t = tb[index];
            r = tbr[index];
            reset( r );
            r.width = t.width;
            r.height = t.height;
            r.centerX = centerX;
            r.y = yy;
            yy += (r.h - 2);
        }

        //var mx = tbr.minmax.fn( _.x );
        //var my = tbr.minmax.fn( _.y );
        //ttr = new Rectangle(mx.min, my.min, (mx.max - mx.min), (my.max - my.min));

        positionTips();
    }

    /**
      * calculate the positions of tooltips
      */
    private function positionTips():Void {
        var startTime = now();
        var coli:Int = 0;
        var columns:Array<Array<SeekBarMarkViewTooltip>> = [new Array()];

        var pr:Rect<Float> = player.view.rect;
        var p:Point<Float> = new Point((pr.x + margin), (pr.y + margin));

        function position(member: SeekBarMarkViewTooltip) {
            var col:Array<SeekBarMarkViewTooltip> = columns[coli];
            if (col == null) {
                col = columns[coli] = new Array();
            }

            member.update( stage );
            member.x = p.x;
            member.y = p.y;
            p.y += (member.h + margin);
            member.calculateGeometry( rect );
            col.push( member );
        }

        function columnWidth(i: Int):Float {
            var result:Float = 0.0;
            var col = columns[i];
            if (col != null) {
                for (m in col) {
                    result = max(result, m.w);
                }
            }
            return result;
        }

        inline function nextColumn():Void {
            var cw = columnWidth( coli );
            ++coli;
            if (columns[coli] == null) {
                columns.insert(coli, new Array());
            }
            p.x += (columnWidth(coli - 1) + (margin * 2));
            p.y = (pr.y + margin);
        }

        for (member in members) {
            position( member );

            if ((member.y + member.h) >= (panel.bar.controls.y - margin)) {
                nextColumn();
                position( member );
            }
        }

        var took:Float = (now() - startTime).fixed( 3 );
        //trace('Positioning tooltips in a grid formation took ${took}ms');
    }

    /**
      * get an Array of all of [this]'s children 
      */
    override function getChildren():Array<Entity> {
        return cast members;
    }

    /**
      * check whether [p] falls within [this]'s content rectangle
      */
    override function containsPoint(p: Point<Float>):Bool {
        if (super.containsPoint( p )) {
            return true;
        }
        else if ( opened ) {
            for (tip in members) {
                if (tip.containsPoint( p )) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
      * append a tooltip to [this] group
      */
    public inline function addTooltip(t: SeekBarMarkViewTooltip):Void {
        members.push( t );
        t.group = this;
        claimChild( t );
        t.hide();
    }

    /**
      * handle bookmark navigation events
      */
    @:access( pman.ui.ctrl.SeekBar )
    @:access( pman.ui.ctrl.SeekBarMarkViewTooltipPanel )
    public function handle_bmnav(event:KeyboardEvent):Void {
        // variable for each 'member's hotkey to be stored in
        var key:HotKey;
        // whether a member was selected by the current event
        var status:Bool = false;
        // if a member was selected, the time that will be seeked to
        var seekTo:Null<Float> = null;
        // iterate over the indices of all members
        for (i in 0...members.length) {
            // get the hotkey for [this] member
            key = SeekBar.HOTKEYS[i];
            // if the event matches the hotkey
            if (SeekBar.checkEventWithHotKey(key, event)) {
                // get the time to be seeked to
                seekTo = members[i].markView.time;
                // set the status to true
                status = true;

                // seek to the specified time
                player.currentTime = seekTo;
                // stop iteration
                break;
            }
        }
        // output debug info
        trace(status ? 'Bookmark selected. Seeking to $seekTo' : 'No bookmark selected');
        // cancel bookmark navigation
        panel.bar.bmnav = false;
    }

    @on('click')
    public function onClick(event: MouseEvent):Void {
        trace('niggers');
    }

    /**
      * get [this] group's hotkey
      */
    @:access(pman.ui.ctrl.SeekBar)
    public inline function getHotKey():Maybe<HotKey> {
        return SeekBar.HOTKEYS[index];
    }

/* === Instance Fields === */

    public var index: Int = 0;
    public var name: String;
    public var word: String;
    public var members: Array<SeekBarMarkViewTooltip>;
    public var panel: SeekBarMarkViewTooltipPanel;

    //-- display fields

    public var margin:Float = 5.0;
    public var yOffset:Float = 0.0;
    public var opacity:Float = 1.0;
    public var opened: Bool = false;
    public var activated: Bool = false;
    public var hovered: Bool = false;
    public var tuning: Array<Bool>;

    private var tb: Array<TextBox>;
    private var ttr: Rect<Float>;
    private var tbr: Array<Rect<Float>>;
    private var colors: Null<Array<Int>> = null;
    private var border: Border;
}
