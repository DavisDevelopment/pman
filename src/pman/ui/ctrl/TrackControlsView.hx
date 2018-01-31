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
        padding.horizontal = 4.0;
        layout = TcvLeft;

        // add all Buttons
        defer(function() {
            //addButton(new TrackAddToPlaylistButton( this ));
            addButton(new TrackStarredButton( this ));
            //TODO separator
            addButton(new TrackShowInfoButton( this ));
            addButton(new TrackEditInfoButton( this ));
            //TODO separator
            addButton(new TrackMoveToTrashButton( this ));
        });
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

        // function that builds a path around [this]'s content rectangle
        inline function dr() {
            c.beginPath();
            c.drawRoundRect(rect, 3.0);
        }

        // draw the background
        dr();
        c.fill();

        // draw the border
        dr();
        c.stroke();

        super.render(stage, c);
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
                stage.cursor = 'default';
            }
        }
    }

    /**
      * calculate the geometry of [this] widget
      */
    override function calculateGeometry(r : Rect<Float>):Void {
        r = playerView.rect;

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

        __positionButtons();

        super.calculateGeometry( r );
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

/* === Computed Instance Fields === */

    public var playerView(get, never):PlayerView;
    private inline function get_playerView() return controls.playerView;

    public var player(get, never):Player;
    private inline function get_player() return playerView.player;

    public var session(get, never):PlayerSession;
    private inline function get_session() return player.session;

    public var uiEnabled(get, never):Bool;
    private inline function get_uiEnabled() return controls.uiEnabled;

/* === Instance Fields === */

    public var buttons : Array<TrackControlButton>;
    public var controls : PlayerControlsView;
    public var hovered : Bool = false;

    public var iconSize : Int;
    public var padding : Padding;
    public var layout : TcvLayout;

    private var colors : Null<Array<Int>>=null;
    private var playingAnimation : Bool = false;
    private var minimized : Bool = false;
}

enum TcvLayout {
    TcvLeft;
    TcvRight;
}
