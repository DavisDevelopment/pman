package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;
import tannus.math.Percent;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.Padding;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.ctrl.PlaybackSpeedWidget;

import vex.core.Document;
import vex.core.Path;

import tannus.math.TMath.*;
import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.math.TMath;

class VolumeWidget extends Ent {
    /* Constructor Function */
    public function new(b : VolumeButton):Void {
        super();

        button = b;

        on('click', onClick);
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        var cols = getColors();
        //plus = Icons.selectionExpand(64, 64, setStroke).toImage();
        //minus = Icons.selectionCollapse(64, 64, setStroke).toImage();
        plus = new VolBtn('selectionExpand', 64, cols);
        minus = new VolBtn('selectionCollapse', 64, cols);
        bar = new Rectangle();
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );

        plus.state = Normal;
        minus.state = Normal;
        if ( player.muted ) {
            plus.state = Disabled;
            minus.state = Disabled;
        }
        else if (player.volume == 1.0) {
            plus.state = Disabled;
        }
        else if (player.volume == 0.0) {
            minus.state = Disabled;
        }

        var mp = stage.getMousePosition();
        if (mp != null && containsPoint( mp )) {
            if (plus.rect.containsPoint( mp ) && plus.state != Disabled) {
                plus.state = Hovered;
            }
            else if (minus.rect.containsPoint( mp ) && minus.state != Disabled) {
                minus.state = Hovered;
            }
        }
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        var cols = getColors();

        c.beginPath();
        c.fillStyle = cols[0].toString();
        c.strokeStyle = cols[2].toString();
        c.drawRoundRect(rect, 2.0);
        c.closePath();
        c.fill();
        c.stroke();

        c.beginPath();
        c.strokeStyle = cols[2].toString();
        c.drawRoundRect(bar, 1.0);
        c.closePath();
        c.stroke();

        var hil = hilited();
        c.beginPath();
        c.fillStyle = cols[(player.muted ? 3 : 1)].toString();
        c.roundRect(bar.x, hil[0], bar.w, hil[1], 1.0);
        c.closePath();
        c.fill();

        var br = plus.rect;
        var bi = plus.image;
        c.drawComponent(bi, 0, 0, bi.width, bi.height, br.x, br.y, br.w, br.h);
        br = minus.rect;
        bi = minus.image;
        c.drawComponent(bi, 0, 0, bi.width, bi.height, br.x, br.y, br.w, br.h);
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        w = 50;
        centerX = button.centerX;
        bar.w = 8;
        bar.h = 100;
        bar.centerX = centerX;
        h = ((btnSize * 2) + bar.h + (margin.top * 4));
        y = (button.y - h - 5);
        bar.y = (y + btnSize + margin.top * 2);
        plus.rect.w = plus.rect.h = minus.rect.w = minus.rect.h = btnSize;
        plus.rect.centerX = centerX;
        minus.rect.centerX = centerX;
        plus.rect.y = (y + margin.top);
        minus.rect.y = (bar.y + bar.h + margin.top);
    }

    /**
      * get the Colors used by [this] widget
      */
    private function getColors():Array<Color> {
        if (colids == null) {
            var bgCol = player.theme.tertiary;
            var barCol = player.theme.secondary;
            var outlineCol = player.theme.primary;
            var disabledCol = outlineCol.lighten( 20 );
            var list = [bgCol, barCol, outlineCol, disabledCol];
            colids = list.map(player.theme.save);
            return list;
        }
        else {
            return colids.map( player.theme.restore );
        }
    }

    /**
      * when [this] gets clicked
      */
    private function onClick(event : MouseEvent):Void {
        var p = event.position;
        if (p.y.inRange(bar.y, (bar.y + bar.h))) {
            onBarClick( event );
        }
        else if (plus.rect.containsPoint( p )) {
            player.volume += 0.05;
        }
        else if (minus.rect.containsPoint( p )) {
            player.volume -= 0.05;
        }
    }

    /**
      * when the 'bar' gets clicked
      */
    public inline function onBarClick(event : MouseEvent) {
        player.volume = getPointFactor( event.position );
    }

    private inline function getPointFactor(p : Point):Float {
        return (((bar.y + bar.h) - p.y) / bar.h);
    }

    /**
      * get the height and the vertical offset of the hilited rect
      */
    private function hilited():Array<Float> {
        var hh = (player.volume * bar.height);
        var hy = (bar.y + bar.height - hh);
        return [hy, hh];
    }

    override function containsPoint(p : Point):Bool {
        return (!isHidden() && super.containsPoint( p ));
    }

    /**
	  * do the stuff
	  */
    private function cancelClick(event : MouseEvent):Void {
        if (!containsPoint( event.position )) {
            event.stopPropogation();
            hide();
        }
    }

    override function show():Void {
        super.show();
        player.view.stage.on('click', cancelClick);
    }

    override function hide():Void {
        super.hide();
        player.view.stage.off('click', cancelClick);
    }

/* === Computed Instance Fields === */

    public var controls(get, never):PlayerControlsView;
    private inline function get_controls():PlayerControlsView return button.controls;

    public var player(get, never):Player;
    private inline function get_player():Player return controls.playerView.player;

/* === Instance Fields === */

    public var button : VolumeButton;
    
    //public var plus : Array<Image>;
    //public var minus : Array<Image>;
    public var plus : VolBtn;
    public var minus : VolBtn;
    //public var plusRect : Rectangle;
    //public var minusRect : Rectangle;
    public var bar : Rectangle;

    private var margin:Padding = {new Padding(3, 3, 3, 3);};
    private var btnSize:Float = 35;
    private var colids:Null<Array<Int>>=null;
}

class VolBtn {
    public var imgList:Array<Image>;
    public var state:VolBtnState;
    public var rect:Rectangle;
    
    public function new(name:String, size:Int, colors:Array<Color>):Void {
        var ic = Obj.fromDynamic( Icons );
        var gen:Int->Int->?(Path->Void)->Document = ic.method( name );
        colors = colors.with([bg, bar, outline, disabled], [outline, bar, disabled]);
        imgList = colors.map.fn([color] => gen(size, size, setcol.bind(_, color)).toImage());
        state = Normal;
        rect = new Rectangle();
    }

    public var image(get, never):Image;
    private inline function get_image():Image return imgList[state];

    private static function setcol(p:Path, color:Color):Void {
        var cs = color.toString();
        p.style.fill = cs;
        p.style.stroke = cs;
    }
}

@:enum
abstract VolBtnState (Int) from Int to Int {
    var Normal = 0;
    var Hovered = 1;
    var Disabled = 2;
}
