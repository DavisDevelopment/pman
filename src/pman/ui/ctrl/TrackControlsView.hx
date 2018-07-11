package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.Padding;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;

import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;
import Slambda.fn;

import motion.Actuate;
import motion.easing.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class TrackControlsView extends Ent {
    /* Constructor Function */
    public function new(pcv : PlayerControlsView):Void {
        super();

        controls = pcv;
        buttons = new Array();

        iconSize = 25;
        padding = new Padding();
        padding.vertical = 3.0;
        padding.horizontal = 6.5;
        layout = TcvLeft;
        status = Minimized;
        max_icon = Icons.plusIcon(iconSize, iconSize).toImage();
        min_icon = Icons.minusIcon(iconSize, iconSize).toImage();
        close_icon = Icons.closeIcon(iconSize, iconSize).toImage();
        min_rect = null;


        // add all Buttons
        defer(function() {
            addButton(new TrackStarredButton( this ));
            //TODO separator
            addButton(new TrackShowInfoButton( this ));
            addButton(new TrackEditInfoButton( this ));
            //TODO separator
            addButton(new TrackMoveToTrashButton( this ));
        });

        on('click', handleClick);
    }

/* === Instance Methods === */

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        if (!uiEnabled || controls.seekBar.bmnav || player.track == null)
            return ;

        var colors = getColors();
        c.save();
        
        // set up drawing options
        c.fillStyle = colors[0];
        c.strokeStyle = colors[1];
        c.lineWidth = 1.5;

        var path = new Path2D();
        path.addRoundRect(rect, 3.0);

        c.fill( path );
        c.stroke( path );

        switch status {
            case Maximized:
                super.render(stage, c);
                // draw the 'window buttons'
                c.fillStyle = colors[0];
                c.strokeStyle = colors[1];
                c.lineWidth = 0.75;
                var path = new Path2D();
                path.addRect(min_rect);
                c.fill( path );
                c.stroke( path );
                c.drawComponent(min_icon, 
                    0, 0, min_icon.width, min_icon.height,
                    min_rect.x, min_rect.y, min_rect.width, min_rect.height
                );

            case Minimized:
                c.drawComponent(max_icon,
                    0, 0, max_icon.width, max_icon.height,
                    x, y, max_icon.width, max_icon.height
                );
        }
        c.restore();
    }

    /**
      * per-frame logic
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        var mp = stage.getMousePosition();
        hovered = (mp != null && containsPoint( mp ));

        if ( hovered ) {
            switch status {
                case Minimized:
                    stage.cursor = 'pointer';

                case Maximized:
                    var hoveredBtn = null;
                    for (b in buttons) {
                        b.hovered = false;
                        if (b.enabled && b.containsPoint( mp )) {
                            hoveredBtn = b;
                        }
                    }
                    if (hoveredBtn != null) {
                        hoveredBtn.hovered = true;
                        stage.cursor = 'pointer';
                    }
                    else {
                        if (min_rect != null && min_rect.containsPoint( mp )) {
                            stage.cursor = 'pointer';
                        }

                        stage.cursor = 'default';
                    }
            }
        }
    }

    /**
      * calculate the geometry of [this] widget
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        r = playerView.rect;

        switch status {
            /* minimized */
            case Minimized:
                min_rect = null;
                h = 25;
                w = 25;
                y = (controls.y - h - padding.vertical);

                switch layout {
                    case TcvLeft:
                        x = (r.x + padding.horizontal);

                    case TcvRight:
                        x = (r.x + r.w - w - padding.horizontal);
                }

            /* maximized */
            case Maximized:
                __calculateHeight();
                switch ( layout ) {
                    case TcvLeft:
                        x = (r.x + padding.horizontal);
                        w = (iconSize + padding.horizontal);
                        y = (controls.y - h - padding.vertical);

                    case TcvRight:
                        w = (iconSize + padding.horizontal);
                        x = (r.x + r.w - w - padding.horizontal);
                        y = (controls.y - h - padding.vertical);
                }

                var wis:Int = floor(iconSize / 2);
                min_rect = new Rect((x - wis), y, wis, wis);

                __positionButtons();

            /* unexpected value */
            default:
                throw 'What the fuck?';
        }

        super.calculateGeometry( r );
    }

    override function containsPoint(p: Point<Float>):Bool {
        return ((min_rect != null && min_rect.containsPoint( p )) || super.containsPoint( p ));
    }

    /**
      * append a new Button to [this]
      */
    public function addButton(btn : TrackControlButton) {
        buttons.push( btn );
        addChild( btn );
        calculateGeometry( rect );
    }

    /**
      * calculate the positions of all buttons attached to [this] widget
      */
    private function __positionButtons():Void {
        var c:Point<Float> = new Point();

        switch ( layout ) {
            case TcvLeft, TcvRight:
                c = new Point((x + padding.left), (y + padding.top));
                for (button in buttons) {
                    if ( !button.enabled )
                        continue;

                    button.x = c.x;
                    button.y = c.y;

                    c.y += (button.h + padding.bottom + padding.top);
                }
        }
    }

    /**
      * calculate the total height of [this] widget based on its contents
      */
    private inline function __calculateHeight():Void {
        var nh:Float = padding.top;
        for (b in buttons) {
            b.calculateGeometry( rect );

            nh += (b.h + padding.vertical);
        }
        h = nh;
    }

    /**
      * get an Array of Colors to be used in the display of [this]
      */
    private function getColors():Array<Color> {
        if (colors == null) {
            var colors = [];

            var cbg = controls.getBackgroundColor();
            colors.push(cbg.lighten( 15 ));
            colors.push(colors[0].lighten( 15 ));

            this.colors = colors.map( theme.save );
            return colors;
        }
        else {
            return colors.map( theme.restore );
        }
    }

    /**
      handle 'click' events
     **/
    function handleClick(event: MouseEvent) {
        switch status {
            case Minimized:
                maximize();
                event.cancel();

            case Maximized:
                //TODO minimize button
                if (min_rect.containsPoint( event.position )) {
                    minimize();
                    event.cancel();
                }
        }
    }

    public function maximize() {
        status = Maximized;
    }

    public function minimize() {
        status = Minimized;
    }

/* === Computed Instance Fields === */

    public var playerView(get, never):PlayerView;
    private inline function get_playerView() return controls.playerView;

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

    public var session(get, never):PlayerSession;
    private inline function get_session() return player.session;

    public var uiEnabled(get, never):Bool;
    private inline function get_uiEnabled() return controls.uiEnabled;

    public var status(default, set): TcvStatus;
    function set_status(value: TcvStatus):TcvStatus {
        var ret = (this.status = value);
        if (playerView != null)
            calculateGeometry( rect );
        return ret;
    }

/* === Instance Fields === */

    public var buttons : Array<TrackControlButton>;
    public var controls : PlayerControlsView;
    public var hovered : Bool = false;

    public var iconSize : Int;
    public var padding : Padding;
    public var layout : TcvLayout;

    private var colors : Null<Array<Int>>=null;
    private var playingAnimation : Bool = false;

    var max_icon: Null<Image> = null;
    var min_icon: Null<Image> = null;
    var close_icon:Null<Image> = null;
    var min_rect:Null<Rect<Float>> = null;
}

enum TcvLayout {
    TcvLeft;
    TcvRight;
}

enum TcvStatus {
    Maximized;
    Minimized;
}
