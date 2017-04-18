package pman.ui.ctrl;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.ui.*;

import tannus.io.Ptr;
import tannus.geom.*;
import tannus.events.MouseEvent;
import tannus.graphics.Color;
import tannus.media.Duration;

import pman.core.*;

import tannus.math.TMath.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

@:access( pman.ui.ctrl.SeekBar )
class ThumbPreviewBox extends Ent {
	/* Constructor Function */
	public function new(seekbar : SeekBar):Void {
		super();

		bar = seekbar;
		border = new Border(6, '#333333', 5);
		tbox = new TextBox();
		tbox.fontFamily = 'Ubuntu';
		tbox.fontSize = 14;
		tbox.fontSizeUnit = 'px';
		tbox.color = '#FFFFFF';
	}

/* === Instance Methods === */

	/**
	  * Initialize [this]
	  */
	override public function init(stage : Stage):Void {
		super.init( stage );
	}

	/**
	  * Update [this]
	  */
	override public function update(stage : Stage):Void {
		super.update( stage );

		updateSize( stage );

		if (target != null) {
			centerX = target.x;
			y = (bar.y - h - 18);


			var progress = bar.hoveredProgress;
			var ct:Duration = Duration.fromFloat(progress.of( bar.player.durationTime ));
			tbox.text = ct.toString();
		}
	}

	/**
	  * Update the dimensions of [this]
	  */
	private function updateSize(stage : Stage):Void {
		if (thumb != null) {
			// 20% of the viewport
			var vp:Rectangle = player.view.rect;

			// scale the thumbnail to be 20% of the viewport height
			var thumbRect:Rectangle = new Rectangle(0, 0, thumb.width, thumb.height);
			thumbRect.scale(null, (0.2 * vp.height));

			w = (max((thumbRect.w + 0.0), tbox.width) + 30);
			h = (thumbRect.h + 20 + 5);
		}
		else {
			w = (tbox.width + 30);
			h = 20;
		}
	}

	/**
	  * Render [this]
	  */
	override public function render(stage:Stage, c:Ctx):Void {
		if ( !bar.hovered ) {
			return ;
		}

		c.save();

		var total = getTotalRect();
		/* draw the time-box */
		c.beginPath();
		c.fillStyle = border.color.toString();
		c.drawRect( total );
		c.closePath();
		c.fill();

		/* draw the time text */
		var ttr:Rectangle = new Rectangle(x, (y + h - 20), w, 20);
		var ttx:Float = (ttr.centerX - (tbox.width / 2));
		var tty:Float = (ttr.centerY - (tbox.height / 2));
		c.drawComponent(tbox, 0, 0, tbox.width, tbox.height, ttx, tty, tbox.width, tbox.height);

		/* draw the thumbnail */
		if (thumb != null) {
			c.drawComponent(thumb, 0, 0, thumb.width, thumb.height, x, y, w, (h - 20));
		}

		/* draw the border */
		c.beginPath();
		c.shadowBlur = 10;
		c.shadowColor = border.color.darken( 12 ).toString();
		c.strokeStyle = border.color.toString();
		c.lineWidth = border.width;
		if (border.radius == 0) {
			c.drawRect( rect );
		}
		else {
			c.drawRoundRect(rect, border.radius);
		}
		c.closePath();
		c.stroke();
		c.restore();
	}

	/**
	  * Get the total Box Rect
	  */
	private function getTotalRect():Rectangle {
		var r:Rectangle = new Rectangle();
		if (thumb != null) {
			r.w = (max(thumb.width, ceil(tbox.width)) + 30);
			r.h = (thumb.height + 25);
		}
		else {
			r.w = ceil(tbox.width + 30);
			r.h = 20;
		}
		if (target != null) {
			r.y = floor(bar.y - r.h - 18);
			r.centerX = target.x;
		}
		return r;
	}

/* === Computed Instance Fields === */

	/* the Player */
	private var player(get, never):Player;
	private inline function get_player():Player return bar.player;

	/* the Thumbnail itself */
	private var thumb(get, never):Null<Canvas>;
	private inline function get_thumb():Null<Canvas> {
		return (bar.thumbnail != null ? bar.thumbnail.image : null);
	}

	/* the Point at which the user is hovering */
	private var target(get, never):Null<Point>;
	private inline function get_target():Null<Point> return bar.hoverLocation;

/* === Instance Fields === */

	public var bar : SeekBar;
	public var border : Border;
	public var tbox : TextBox;
}
