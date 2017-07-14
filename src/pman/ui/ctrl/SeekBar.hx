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
import pman.ui.ctrl.SeekBarMarkView;
import pman.ui.ctrl.SeekBarMarkView as MarkView;
import pman.async.SeekbarPreviewThumbnailLoader as ThumbLoader;

import tannus.math.TMath.*;
import gryffin.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.TMath;

@:access( pman.ui.PlayerControlsView )
class SeekBar extends Ent {
    /* Constructor Function */
    public function new(c : PlayerControlsView):Void {
        super();

        controls = c;
        viewed = new Rectangle();
        hoverLocation = null;
        hovered = false;
        lhct = now;

        thumb = new ThumbPreviewBox( this );
        markViewPanel = new SeekBarMarkViewTooltipPanel( this );
        ctb = new TextBox();
        dtb = new TextBox();
        __itb( ctb );
        __itb( dtb );
        tb_margin = 0;

        markViews = new Array();
    }

    /* === Instance Methods === */

    /**
     * initialize [this]
     */
    override function init(stage : Stage):Void {
        super.init( stage );

        controls.addSibling( thumb );
        controls.addSibling( markViewPanel );

        on('click', onClick);
        on('contextmenu', onRightClick);
        on('mousemove', onMouseMove);

        __listen();
    }

    /**
      * initiate bookmark navigation
      */
    public function bookmarkNavigation():Void {
        if ( !bmnav ) {
            bmnav = true;
            playerView.controls.lockUiVisibility();
            playerView.controls.showUi();
            player.app.keyboardCommands.nextKeyDown( bmnavHandler );
        }
    }

    /**
      * the bookmark-navigation handler
      */
    private function bmnavHandler(event : KeyboardEvent):Void {
        for (mv in markViews) {
            var hkey = mv.hotKey();
            if (hkey != null && hkey.key == event.key && hkey.shift == event.shiftKey) {
                mv.tooltip.activate();
                player.currentTime = mv.time;
                break;
            }
        }
        bmnav = false;
        playerView.controls.unlockUiVisibility();
    }

    /**
      * construct the list of views for the track's marks
      */
    private function buildMarkViews():Void {
        // previous markviews
        //var _pmv = markViews;
        markViews = new Array();
        navMarkViews = new Array();
        markViewPanel.clear();
        _lfml = null;
        
        for (mvt in getMarkViewTypes()) {
            var markView = new MarkView(this, mvt);
            markViews.push( markView );
            if (markView.canNavigateTo()) {
                navMarkViews.push( markView );
                markViewPanel.addTooltip( markView.tooltip );
            }
        }
    }

    /**
      * obtain list of MarkViewType values
      */
    private function getMarkViewTypes():Array<MarkViewType> {
        var types:Array<MarkViewType> = new Array();
        if (player.track != null && player.track.data != null) {
            var marks = player.track.data.marks;
            var markTimes:Array<Float> = new Array();
            for (m in marks) if (m.type.match(Named(_))) {
                types.push(MarkViewType.MTReal( m ));
                if (!inFloats(m.time, markTimes))
                    markTimes.push( m.time );
            }

            var bundle = player.track.getBundle();
            var ssitems = bundle.getAllSnapshots();
            var times:Array<Float> = new Array();
            for (item in ssitems) {
                var time = item.getTime();
                if (time != null && !inFloats(time, times))
                    times.push( time );
            }
            for (time in times) {
                types.push(MarkViewType.MTSnapshot( time ));
            }
        }

        // get type time
        function typetime(t : MarkViewType):Float {
            return switch (t) {
                case MarkViewType.MTReal(m): m.time;
                case MarkViewType.MTSnapshot(time): time;
            };
        }
        haxe.ds.ArraySort.sort(types, function(x, y) {
            return Reflect.compare(typetime(x), typetime(y));
        });
        return types;
    }

    private function inFloats(n:Float, i:Iterable<Float>, threshold:Float=1.0):Bool {
        for (x in i) {
            if (n.almostEquals(x, threshold))
                return true;
        }
        return false;
    }

    /**
     * update [this]
     */
    override function update(stage : Stage):Void {
        super.update( stage );

        var lastHovered:Bool = hovered;
        var lastHoverLocation:Null<Point> = hoverLocation;
        var mp = stage.getMousePosition();
        hovered = (mp != null && containsPoint( mp ) && sess.hasMedia());
        hoverLocation = hovered ? mp : null;

        if (hovered && hoverLocation != null) {
            var hoverStatusChanged:Bool = (!lastHovered || (lastHoverLocation == null || hoverLocation.nequals( lastHoverLocation )));
            if ( hoverStatusChanged ) {
                lhct = now;
            }
            else {
                var sinceLast:Float = (now - lhct);
                // if the last hover-status change was more than 2.5sec ago, and no thumbnail is currently being loaded
                if (sinceLast > 800 && !loadingThumbnail) {
                    // if there is already a thumbnail loaded, and it was loaded more recently than the last hover-status change
                    if (thumbnail != null && thumbnail.loadedAt > lhct) {
                        null;
                    }
                    else {
                        loadThumbnail();
                    }
                }
                else if (thumbnail != null) {
                    thumbnail = null;
                    loadingThumbnail = false;
                }
            }
        }
        else {
            thumbnail = null;
            loadingThumbnail = false;
        }

        __updateTextBoxes( stage );
        __updateViewed( stage );

        // rebuild the mark views when the track's marks array changes
        if (player.track != null && player.track.data != null) {
            // track's current marks
            var marks = player.track.data.marks;
            if (_lfml != null) {
                // check for actual equality, i.e. the two arrays are in fact just two references to the same array
                var same = (marks == _lfml);
                // if this is the case
                if ( same ) {
                    // nothing to do in this case
                }
                else {
                    // rebuild the mark views to reflect this change
                    buildMarkViews();
                    // update [_lfml]
                    _lfml = marks;
                }
            }
            else {
                if (marks.length != markViews.length) {
                    buildMarkViews();
                }

                _lfml = marks;
            }
        }

        calculateGeometry( rect );
    }

    /**
     * draw [this]
     */
    override function render(stage:Stage, c:Ctx):Void {
        super.render(stage, c);

        var bg = getBackgroundColor();
        var fg = getForegroundColor();

        // draw background
        c.fillStyle = bg.toString();
        c.beginPath();
        c.drawRect( rect );
        c.closePath();
        c.fill();

        // draw the viewed rectangle
        c.fillStyle = fg.toString();
        c.beginPath();
        c.drawRect( viewed );
        c.closePath();
        c.fill();

        // draw the bookmark tabs
        var deferred = [];
        for (mv in markViews) {
            if (mv.canNavigateTo())
                deferred.push( mv );
            else
                drawMarkView(mv, stage, c);
        }
        for (mv in deferred)
            drawMarkView(mv, stage, c);

        // draw the seek-caret
        if ( hovered ) {
            c.fillStyle = (viewed.containsPoint(hoverLocation)?fg.invert():fg).toString();
            c.beginPath();
            c.rect((hoverLocation.x - 2), y, 4.0, viewed.h);
            c.closePath();
            c.fill();
        }

        // draw the current time
        var ctbx:Float = controls.x + (((x - controls.x) - ctb.width) / 2);
        c.drawComponent(ctb, 0, 0, ctb.width, ctb.height, ctbx, y, ctb.width, ctb.height);

        // draw the duration
        var dtbx:Float = x + w + ((((controls.x + controls.w) - (x + w)) - dtb.width) / 2);
        c.drawComponent(dtb, 0, 0, dtb.width, dtb.height, dtbx, y, dtb.width, dtb.height);

    }

    /**
      * draw the given mark view
      */
    private function drawMarkView(mv:MarkView, stage:Stage, c:Ctx):Void {
        c.save();

        var p:Point = mv.pos();
        var mw:Float = 0;

        switch (mv.getIndicatorType()) {
            case MarkViewIndicator.MIBox(fill):
                mw = (0.575 * h);
                p.x -= (mw / 2);
                c.fillStyle = fill;
                c.fillRect(p.x, p.y, mw, h);

            case MarkViewIndicator.MIBar(color):
                mw = 1.5;
                p.x -= (mw / 2);
                c.fillStyle = color;
                c.fillRect(p.x, p.y, mw, h);
        }

        c.restore();
    }

    /**
     * calculate [this]'s geometry
     */
    override function calculateGeometry(r : Rectangle):Void {
        w = (controls.w - (tb_margin * 2));
        h = 12;
        centerX = controls.centerX;
        y = (controls.y + 5.0);
    }

    /**
     * begin loading the thumbnail
     */
    private function loadThumbnail():Void {
        var track = player.session.focusedTrack;
        if (track != null) {
            var driver = track.driver;
            if (driver.hasMediaObject()) {
                var mo = driver.getMediaObject();
                if (mo != null && Std.is(mo, Video)) {
                    var video = cast(mo, Video);
                    loadingThumbnail = true;
                    var loader = new ThumbLoader(track, this);
                    var cp = loader.loadPreview(floor(getCurrentTime()), video);
                    cp.then(function( canvas ) {
                        thumbnail = {
                            image: canvas,
                            loadedAt: now
                        };
                        loadingThumbnail = false;
                    });
                    cp.unless(function( error ) {
                        trace('Error: $error');
                        loadingThumbnail = false;
                    });
                }
                else {
                    return ;
                }
            }
            else {
                return ;
            }
        }
        else {
            return ;
        }
    }

    /**
     * update the 'viewed' rect
     */
    private function __updateViewed(stage : Stage):Void {
        var v = viewed;
        v.x = x;
        v.y = y;
        v.h = h;

        // if there is media loaded currently
        if (pd != null) {
            if ( false ) {
                var mx = hoverLocation.x;
                mx -= x;
                v.w = mx;
            }
            else {
                var total = pd.getDurationTime();
                var time = pd.getCurrentTime();
                var perc = Percent.percent(time, total);

                v.w = perc.of( w );
            }
        }
        // if there is not
        else {

            v.w = 0.0;

        }
    }

    /**
     * update the text boxes
     */
    private function __updateTextBoxes(stage : Stage):Void {
        var cdur = Duration.fromFloat( player.currentTime );

        ctb.text = cdur.toString();
        dtb.text = player.duration.toString();

        var mwtb:Float = max(ctb.width, dtb.width);
        mwtb += (mwtb * 0.2);
        tb_margin = mwtb;
    }

    /**
     * initialize the text boxes
     */
    private inline function __itb(t : TextBox):Void {
        t.fontFamily = 'Ubuntu';
        t.fontSizeUnit = 'px';
        t.fontSize = 10;
        t.color = '#FFFFFF';
    }

    /**
     * get the background color
     */
    private function getBackgroundColor():Color {
        // if color exists and has been cached
        if (controls.cidm.exists('sb-bg')) {
            return player.theme.restore(controls.cidm['sb-bg']);
        }
        // if the color has not yet been cached
        else {
            // create the Color
            var color = player.theme.primary.darken( 14.0 );
            // cache the Color
            controls.cidm['sb-bg'] = player.theme.save( color );
            // return the Color
            return color;
        }
    }

    /**
     * get the foreground color
     */
    private function getForegroundColor():Color {
        return player.theme.secondary;
    }

    /**
     * handle click events
     */
    private function onClick(event : MouseEvent):Void {
        var ex:Float = event.position.x;
        ex -= x;
        var perc:Percent = Percent.percent(ex, w);
        if (pd != null) {
            var ts:Float = pd.getDurationTime();
            pd.setCurrentTime(perc.of( ts ));
        }
    }

    /**
      * handle right-click events
      */
    private function onRightClick(event : MouseEvent):Void {
        null;
    }

    /**
      * handle mouse-move events
      */
    private function onMouseMove(event : MouseEvent):Void {
        thumbnail = null;
    }

    /**
     * get the percentage of the duration of the media, represented by either 
     * the media's currentTime or the time being hovered over by the user
     */
    private inline function getCurrentPercent():Percent {
        return Percent.percent(viewed.w, w);
    }

    /**
     * get the time referred to by either currentTime or the time being hovered
     */
    private inline function getCurrentTime():Float {
        return (hovered ? hoveredProgress : progress).of(pd.getDurationTime());
    }

    /**
      * bind any needed event handlers
      */
    private function __listen():Void {
        var bundle:Maybe<Bundle> = player.track!=null?player.track.getBundle():null;
        sess.trackChanged.on(function(delta) {
            if (bundle != null)
                bundle.unwatch( __bundleChanged );
            buildMarkViews();
            bundle = delta.current.ternary(_.getBundle(),null);
            if (bundle != null) {
                bundle.watch( __bundleChanged );
            }
        });

        if (bundle != null) {
            bundle.watch( __bundleChanged );
        }
    }

    /**
      * respond to changes occurring on a Track's Bundle instance
      */
    private function __bundleChanged(change : BundleItem):Void {
        buildMarkViews();
    }

/* === Computed Instance Fields === */

    public var playerView(get, never):PlayerView;
    private inline function get_playerView():PlayerView return controls.playerView;

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

    public var sess(get, never):PlayerSession;
    private inline function get_sess():PlayerSession return player.session;

    private var pd(get, never):Null<PlaybackDriver>;
    private inline function get_pd() return sess.playbackDriver;

    public var progress(get, never):Percent;
    private inline function get_progress():Percent return getCurrentPercent();

    public var hoveredProgress(get, never):Null<Percent>;
    private function get_hoveredProgress():Null<Percent> {
        if (hoverLocation != null) {
            return Percent.percent((hoverLocation.x - x), w);
        }
        else return null;
    }

    /* === Instance Fields === */

    public var controls : PlayerControlsView;
    public var hoverLocation : Null<Point>;
    public var hovered(default, null):Bool;
    public var bmnav : Bool = false;

    private var viewed : Rectangle;

    private var thumb : ThumbPreviewBox;
    private var markViewPanel : SeekBarMarkViewTooltipPanel;
    private var ctb:TextBox;
    private var dtb:TextBox;
    private var tb_margin:Float;

    // last hover change time -- or the last time the hover-status changed
    private var lhct:Float;
    private var loadingThumbnail:Bool = false;
    private var thumbnail : Null<Thumbnail> = null;
    private var markViews : Array<MarkView>;
    private var navMarkViews : Array<MarkView>;
    // last frame's mark list
    private var _lfml : Null<Array<Mark>> = null;

    private static var KEYCODES:Array<Key>;
    private static var HOTKEYS:Array<HotKey>;

    private static function __init__():Void {
        KEYCODES = [
            Number1,Number2,Number3,Number4,Number5,Number6,Number7,Number8,Number9,
            LetterA,LetterB,LetterC,LetterD,LetterE,LetterF,LetterG,LetterH,LetterI,
            LetterJ,LetterK,LetterL,LetterM,LetterN,LetterO,LetterP,LetterQ,LetterR,
            LetterS,LetterT,LetterU,LetterV,LetterW,LetterY,LetterZ
        ];
        HOTKEYS = new Array();
        for (i in 0...9) {
            HOTKEYS.push({key: KEYCODES[i], shift: false});
        }
        for (i in 9...KEYCODES.length) {
            HOTKEYS.push({key:KEYCODES[i], shift: false});
        }
        for (i in 9...KEYCODES.length) {
            HOTKEYS.push({key:KEYCODES[i], shift: true});
        }
    }
}

typedef Thumbnail = {
    image : Canvas,
    loadedAt : Float
};

typedef HotKey = {
    key: Key,
    shift: Bool
};
