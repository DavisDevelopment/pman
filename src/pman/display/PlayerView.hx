package pman.display;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.Tools.*;
import electron.MenuTemplate;
import electron.ext.Menu;

import pman.core.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.hud.*;
import pman.ui.tabs.*;
import pman.ui.statusbar.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PlayerView extends Ent {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();
		
		player = p;

		currentMediaRenderer = null;
		mediaRect = new Rectangle();

        // await readiness of the Player
        //player.onReady(function() {
            // create controls view
            controls = new PlayerControlsView( this );
            addSibling( controls );

            // create status bar
            statusBar = new PlayerStatusBar( this );
            addSibling( statusBar );

            // create message board
            messageBoard = new PlayerMessageBoard( player );
            addSibling( messageBoard );

            // create HUD
            hud = new PlayerHUD( this );
            addSibling( hud );

            tabBar = new TabViewBar( this );
            addSibling( tabBar );

            dragDropWidget = new DragDropWidget( this );
            addSibling( dragDropWidget );
        //});
	}

/* === PMan Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {
        on('contextmenu', onRightClick);
    }

	/**
	  * detach the current renderer from [this] view, and deallocate its memory
	  */
	public function detachRenderer():Void {
		// if [this] view even has media
		if (currentMediaRenderer != null) {
			// alert the renderer that it is being detached
			currentMediaRenderer.onDetached( this );
			// deallocate that media
			currentMediaRenderer.dispose();

			// unlink it from [this] Object
			currentMediaRenderer = null;
		}
	}

	/**
	  * attach the given renderer to [this] view
	  */
	public function attachRenderer(mr : MediaRenderer):Void {
		// if [mr] isn't already attached to [this] view
		if (mr != currentMediaRenderer) {
			// if [this] view already has an attached renderer
			if (currentMediaRenderer != null) {
				// unlink it
				detachRenderer();
			}

			// now link the new one
			currentMediaRenderer = mr;
			currentMediaRenderer.onAttached( this );
		}
	}

/* === Gryffin Methods === */

	/**
	  * Update [this]
	  */
	override function update(stage : Stage):Void {
		// echo the playback properties onto the current media
		if (cmr != null) {
            cmr.update( stage );
		}

		player.tick();

		super.update( stage );
	}

	/**
	  * Render [this]
	  */
	override function render(stage:Stage, c:Ctx):Void {
	    // clear [this]'s rect
	    c.clearRect(x, y, w, h);

		// if [this] view has media
		if (cmr != null) {
			// render that media
			cmr.render(stage, c);
		}
		
		// render everything else
		super.render(stage, c);
	}

	/**
	  * calculate [this]'s geometry
	  */
	override function calculateGeometry(r : Rectangle):Void {
		if ( !player.isReady )
		    return ;

		rect.cloneFrom( r );

        if ( tabBar.display ) {
            h -= tabBar.h;
            y += tabBar.h;
        }

		if ( controls.uiEnabled ) {
			h -= controls.h;
		}
		if (player.isPlaylistOpen()) {
			var plv = player.getPlaylistView();
			w -= plv.width;
		}
		
		super.calculateGeometry( r );

		if (cmr != null) {
			cmr.calculateGeometry( rect );
		}
	}

    /**
      * handle right click events
      */
    public function onRightClick(event : MouseEvent):Void {
        var p = event.position;
        player.buildMenu(function( template ) {
            var menu:Menu = template;
            menu.popup(p.x, p.y);
        });
    }

/* === Computed Instance Fields === */

	public var cmr(get, set):Null<MediaRenderer>;
	private inline function get_cmr():Null<MediaRenderer> return currentMediaRenderer;
	private inline function set_cmr(v : Null<MediaRenderer>):Null<MediaRenderer> return (currentMediaRenderer = v);

/* === Instance Fields === */

	public var player : Player;
	public var controls : PlayerControlsView;
	public var messageBoard : PlayerMessageBoard;
	public var statusBar : PlayerStatusBar;
	public var hud : PlayerHUD;
	public var tabBar : TabViewBar;
	public var dragDropWidget : DragDropWidget;
	public var mediaRect : Rectangle;

	public var currentMediaRenderer : Null<MediaRenderer>;

	private var lastStatus : Null<PlayerStatus> = null;
}
