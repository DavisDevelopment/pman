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
import pman.ui.ctrl.VolumeWidget;

import tannus.math.TMath.*;
import electron.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PlaybackSpeedWidget extends Ent {
	/* Constructor Function */
	public function new(c:PlayerControlsView, b:PlaybackSpeedButton):Void {
		super();

		controls = c;
		button = b;

		//hide();
	}

/* === Instance Methods === */

	/**
	  * initialize [this]
	  */
	override function init(stage : Stage):Void {
		var colors = getColors();
		minus = new VolBtn('selectionCollapse', Std.int(btnSize[0]), colors);
		plus = new VolBtn('selectionExpand', Std.int(btnSize[0]), colors);

		super.init( stage );
		hide();
		on('click', onClick);
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

	/**
	  * update [this]
	  */
	override function update(stage : Stage):Void {
		super.update( stage );
        plus.state = Normal;
        minus.state = Normal;
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
	@:access( pman.ui.PlayerControlsView )
	override function render(stage:Stage, c:Ctx):Void {
		var colors = getColors();
		inline function col(i:Int) return Std.string(colors[i]);

		c.beginPath();
		c.fillStyle = col( 0 );
		c.strokeStyle = col( 2 );
		c.drawRoundRect(rect, 2);
		c.closePath();
		c.fill();
		c.stroke();

		var bi:Image=minus.image, br:Rectangle=minus.rect;
		c.drawComponent(bi, 0, 0, bi.width, bi.height, br.x, br.y, br.w, br.h);
		bi = plus.image;
		br = plus.rect;
		c.drawComponent(bi, 0, 0, bi.width, bi.height, br.x, br.y, br.w, br.h);

		super.render(stage, c);
	}

	/**
	  * calculate [this]'s geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
	    inline function double(x:Float) return (x * 2);
		//w = ((btnSize[1] * 2) + (margin.left * 2) + (margin.right * 2));
	    w = (double(btnSize[1]) + double( margin.left ) + double( margin.right ));
	    h = (btnSize[1] + double( margin.top ));
	    centerX = button.centerX;
	    y = (button.y - h - margin.bottom);
	    var br = minus.rect;
	    br.x = (x + margin.left);
	    br.y = (y + margin.top);
	    br.w = br.h = btnSize[1];
	    br = plus.rect;
	    br.w = br.h = btnSize[1];
	    br.x = (x + w - br.w - margin.right);
	    br.y = (y + margin.top);
	}

    /**
      * check whether [this] contains [p]
      */
	override function containsPoint(p : Point):Bool {
	    return (!isHidden() && super.containsPoint( p ));
	}

	/**
	  * handle click events
	  */
	private function onClick(event : MouseEvent):Void {
	    var jump:Float = 0.05;
	    if (minus.rect.containsPoint( event.position )) {
	        player.playbackRate -= jump;
	    }
        else if (plus.rect.containsPoint( event.position )) {
            player.playbackRate += jump;
        }
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

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player():Player return controls.playerView.player;

/* === Instance Fields === */

	public var controls : PlayerControlsView;
	public var button : PlaybackSpeedButton;

	private var margin:Padding = {new Padding(3, 3, 3, 3);};
	private var plus : VolBtn;
	private var minus : VolBtn;
	private var btnSize:Array<Float> = [64, 35];
	private var colids : Null<Array<Int>> = null;
	//private var totalWidth : Float;
	//private var totalHeight : Float;
}
