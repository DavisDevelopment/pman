package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.media.Duration;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.math.Time;
import tannus.events.MouseEvent;
import pman.events.KeyboardEvent;
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
        tbu = [false, false, false];
        tbr = [new Rect(), new Rect(), new Rect()];
        border = new Border(3.0, player.theme.primary.lighten( 20 ), 3.0);
    }

/* === Instance Methods === */

    /**
      * 'open' [this] group, revealing all sub-marks to
      */
    public function open():Void {
        //positionTips();

        this.opened = true;
        dispatch('opened', this);
    }

    /**
      * close [this] group
      */
    public function close():Void {
        this.opened = false;
        dispatch('closed', this);
    }

    /**
      * perform per-frame logic
      */
    override function update(stage: Stage):Void {
        super.update( stage );

        // whether [this] group has changed since last time its geometry was updated
        var changed:Bool = (members.length != lastMembersLength || index != lastIndex);

        // if so, update [this]
        if ( changed ) {
            // update [name]
            if (members.length == 1) {
                name = (members[0].markView.name).wrap(' ');
            }
            else {
                name = (word + ' ...');
            }
        }

        // get info
        var colors = getColors();
        var key = getHotKey();

        if (lastTime == null) {
            lastTime = now();
        }
        else {
            var sinceLastTime:Float = (now() - lastTime);
            // if it's been more than a second since last update
            if (sinceLastTime >= 1000) {
                changed = true;
                lastTime = now();
            }
            else {
                null;
            }
        }

        // update text-boxes and whatnot
        _update(colors, key);

        changed = (changed || tbu.has( true ));

        trace('mark group changed: $changed');
        
        if ( changed ) {
            calculateGeometry(cast stage.rect);
        }
        else if ( opened ) {
            for (tip in members) {
                tip.update( stage );
            }
        }

        lastMembersLength = members.length;
        lastIndex = index;
    }



    /**
      * do the stuff
      */
    private function _update(colors:Array<Color>, ?k:Null<HotKey>):Void {
        // -- first text box
        configTextBox(0, name, colors[0], null, 12, 'px', true);

        // -- second text box
        var txt:String = (members.length == 1 ? Time.fromFloat(members[0].markView.mark.time).toString() : (members.length + ' items'));
        configTextBox(1, txt, colors[0], null, 8.5, 'px');


        // -- third text box
        txt = '';
        if (k != null) {
            txt = (k.char.aschar.toLowerCase());
            if ( k.shift ) {
                txt = txt.toUpperCase();
            }
        }
        configTextBox(2, '($txt)', colors[1], "Dosis", 10.0, 'px');


        // -- calculate total text content rect
        ttr = new Rect();
        if ( !bubble ) {
            for (t in tb) {
                ttr.width = max(ttr.width, t.width);
                ttr.height += t.height;
            }
        }
        else {
            for (t in tb.slice(0, -1)) {
                ttr.width = max(ttr.width, t.width);
                ttr.height += t.height;
            }
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r: Rect<Float>):Void {
        inline function dbl(x:Float):Float return (x * 2);
        inline function reset(r: Rect<Float>) r.x = r.y = r.w = r.h = 0.0;

        // set content rectangle
        w = (ttr.width + dbl(dbl(margin)));
        h = (ttr.height + margin);

        // calculate text-box geometry
        var yy:Float = (y + margin);
        var t:TextBox, r:Rect<Float>;
        if ( !bubble ) {
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
        }
        else {
            for (index in 0...(tb.length - 1)) {
                t = tb[index];
                r = tbr[index];
                reset( r );

                r.width = t.width;
                r.height = t.height;
                r.centerX = centerX;
                r.y = yy;
                yy += (r.h - 2);
            }

            t = tb[index = (tb.length - 1)];
            r = tbr[index];
            reset( r );

            r.width = t.width;
            r.height = t.height;

            // position text-rect such that its top-left corner is on [this]'s rect's bottom-right
            r.x = (x + w);
            r.y = (y + h);
        }
        tbu = [false, false, false];

        positionTips();
    }

    /**
      * calculate the positions of tooltips
      */
    private function positionTips():Void {
        // the start time for [this] task
        var startTime = now();

        // column index
        var coli:Int = 0;

        // array of columns
        var columns:Array<Array<SeekBarMarkViewTooltip>> = [new Array()];

        // player view rectangle
        var pr:Rect<Float> = player.view.rect;

        // 'current' point
        var p:Point<Float> = new Point((pr.x + margin), (pr.y + margin));

        /**
          * position a single tooltip
          */
        function position(member: SeekBarMarkViewTooltip) {
            // current column
            var col:Array<SeekBarMarkViewTooltip> = columns[coli];

            // create that column if it's not there
            if (col == null) {
                col = columns[coli] = new Array();
            }

            // update [member]
            member.update( stage );

            // position the [member]
            member.x = p.x;
            member.y = p.y;

            p.y += (member.h + margin);

            // calculate the geometry of [rect]
            member.calculateGeometry( rect );

            // add [member] to [col]
            col.push( member );
        }

        /**
          * calculate the column width
          */
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

        /**
          * move on to the next column
          */
        inline function nextColumn():Void {
            var cw = columnWidth( coli );
            ++coli;
            if (columns[coli] == null) {
                columns.insert(coli, new Array());
            }
            p.x += (columnWidth(coli - 1) + (margin * 2));
            p.y = (pr.y + margin);
        }

        // iterate over each member
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
      * render [this] group
      */
    override function render(stage:Stage, c:Ctx):Void {
        // 
        if (!panel.hasOpenTooltipGroup()) {
            // if [ttr] hasn't been initialized yet
            if (ttr == null) {
                // calculate geometry
                calculateGeometry( rect );
            }

            //- get color list
            var colors = getColors();

            //- draw background
            //draw_bg(c, colors);

            //- draw border
            //draw_border(c, colors);
            draw_bg_and_border(c, colors);

            // draw textual data
            /*
            for (index in 0...tb.length) {
                var t = tb[index];
                var r = tbr[index];
                c.drawComponent(t, 0, 0, t.width, t.height, r.x, r.y, r.w, r.h);
            }
            */
            draw_text( c );
        }

        // was: if (members.length > 2)...
        // why did I do that?
        if (members.length > 1) {
            /*
            for (t in members) {
                if (!t._hidden && shouldChildRender(cast t)) {
                    t.render(stage, c);
                }
            }
            */

            //
            if ( opened ) {
                for (t in members) {
                    if (shouldChildRender(cast t)) {
                        t.render(stage, c);
                    }
                }
            }
        }
    }

    /**
      * draw [this]'s background
      */
    private inline function draw_bg(c:Ctx, colors:Array<Color>):Void {
        c.beginPath();
        c.fillStyle = colors[1];
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.fill();
    }

    /**
      * draw the border
      */
    private inline function draw_border(c:Ctx, colors:Array<Color>):Void {
        c.beginPath();
        c.strokeStyle = border.color;
        c.lineWidth = border.width;
        c.drawRoundRect(rect, border.radius);
        c.closePath();
        c.stroke();
    }

    /**
      * draws background AND border all at once, building the path only once
      * (magic)
      */
    private inline function draw_bg_and_border(c:Ctx, colors:Array<Color>):Void {
        draw_bg(c, colors);
        c.strokeStyle = border.color;
        c.lineWidth = border.width;
        c.stroke();
    }

    /**
      * draw the text-boxes
      */
    private inline function draw_text(c: Ctx):Void {
        var t:TextBox, r:Rect<Float>;
        for (index in 0...tb.length) {
            t = tb[index];
            r = tbr[index];
            c.drawComponent(t, 0, 0, t.width, t.height, r.x, r.y, t.width, t.height);
        }
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
        trace('you did me a click');
    }

    /**
      * get [this] group's hotkey
      */
    @:access(pman.ui.ctrl.SeekBar)
    public inline function getHotKey():Maybe<HotKey> {
        return SeekBar.HOTKEYS[index];
    }

    /**
      * get the colors used by [this]
      */
    private static function getColors():Array<Color> {
        if (colors == null) {
            return colors = [
                new Color(255, 255, 255),
                player.theme.primary
            ];
        }
        return colors;
    }

    /**
      * configure a text box
      */
    private function configTextBox(index:Int, ?text:String, ?color:Color, ?fontFamily:String, ?fontSize:Float, ?fontSizeUnit:String, ?bold:Bool) {
        var t:TextBox = tb[index];

        // flag the TextBox as having been updated if [a] and [b] are not equal
        inline function comp<T>(a:T, b:T) {
            if (a != b) {
                tbu[index] = true;
            }
        }

        // text content
        if (text != null) {
            comp(text, t.text);
            t.text = text;
        }

        // text color
        if (color != null) {
            //comp(color, t.color);
            if (!tbu[index] && !t.color.equals( color ))
                tbu[index] = true;
            t.color = color;
        }

        // text font family
        if (fontFamily != null) {
            comp(fontFamily, t.fontFamily);
            t.fontFamily = fontFamily;
        }

        // text font size
        if (fontSize != null) {
            comp(fontSize, t.fontSize);
            t.fontSize = fontSize;
        }

        // text font size unit (e.g. "pt")
        if (fontSizeUnit != null) {
            comp(fontSizeUnit, t.fontSizeUnit);
            t.fontSizeUnit = fontSizeUnit;
        }

        // text boldness
        if (bold != null) {
            comp(bold, t.bold);
            t.bold = bold;
        }
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
    public var bubble: Bool = false;
    public var tuning: Array<Bool>;

    // TextBox Array
    private var tb: Array<TextBox>;

    // TextBox 'updated' statuses
    private var tbu: Array<Bool>;

    // total text rect
    private var ttr: Rect<Float>;

    // TextBox Rect Array
    private var tbr: Array<Rect<Float>>;

    // last time [this] updated
    private var lastTime:Null<Float> = null;

    // Thumbnail images
    private var thumbs: Null<Array<Image>> = null;
    private var loading_thumbs: Bool = false;

    // Color handle array
    //private var colors: Null<Array<Int>> = null;
    private static var colors:Null<Array<Color>> = null;

    // border
    private var border: Border;

    //-- state fields

    private var lastMembersLength:Int = 0;
    private var lastIndex:Int = 0;
}

typedef TextBoxProps = {
    ?color: Color,
    ?fontFamily: String,
    ?fontSize: Float,
    ?fontSizeUnit: String,
    ?bold: Bool
};
