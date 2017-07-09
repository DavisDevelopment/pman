package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
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

        iconSize = 30;
        padding = new Padding();
        padding.vertical = 4.0;
        padding.horizontal = 4.0;
        layout = TcvLeft;

        // add all Buttons
        defer(function() {
            addButton(new TrackStarredButton( this ));
        });
    }

/* === Instance Methods === */

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        if (!uiEnabled || controls.seekBar.bmnav)
            return ;

        var colors = getColors();

        c.save();
        
        if (!hovered)
            c.globalAlpha = 0.45;
        c.beginPath();
        c.fillStyle = colors[0];
        c.drawRoundRect(rect, 2.0);
        c.closePath();
        c.fill();

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
    }

    /**
      * calculate the geometry of [this] widget
      */
    override function calculateGeometry(r : Rectangle):Void {
        r = playerView.rect;

        switch ( layout ) {
            case TcvLeft:
                x = (r.x + padding.horizontal);
                y = r.y;
                w = (iconSize + padding.horizontal);
                h = 0.0;

            case TcvRight:
                w = (iconSize + padding.horizontal);
                x = (r.x + r.w - w - padding.horizontal);
                y = r.y;
                h = 0.0;
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
        var c:Point = new Point();

        switch ( layout ) {
            case TcvLeft, TcvRight:
                c = new Point((x + padding.left), (y + padding.top));
                for (button in buttons) {
                    if ( !button.enabled )
                        continue;
                    button.calculateGeometry( rect );

                    button.x = c.x;
                    button.y = c.y;

                    c.y += (button.h + padding.bottom + padding.top);
                }
                h = c.y;
        }
    }

    private function getColors():Array<Color> {
        if (colors == null) {
            var colors = [];
            var cbg = controls.getBackgroundColor();
            colors.push(cbg.lighten( 15 ));
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
}

enum TcvLayout {
    TcvLeft;
    TcvRight;
}
