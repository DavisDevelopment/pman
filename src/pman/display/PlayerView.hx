package pman.display;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.Tools.*;
import electron.MenuTemplate;
import electron.ext.Menu;
//import electron.main.Menu;

import pman.core.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.hud.*;
import pman.ui.tabs.*;
import pman.ui.statusbar.*;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.FunctionTools;
using tannus.async.Asyncs;

class PlayerView extends Ent {
	/* Constructor Function */
	public function new(p : Player):Void {
		super();
		
		player = p;

		currentMediaRenderer = null;
		mediaRect = new Rect();

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
        defer(function() {
            __listen();
        });
    }

    /**
      * bind event handlers
      */
    private function __listen():Void {
        inline function pon<T>(n:String, f:T->Void) player.on(n, f);
        inline function ponce<T>(n:String, f:T->Void) player.once(n, f);

        on('contextmenu', onRightClick);
        
        pon('tabswitching', function(d: Delta<PlayerTab>) {
            //TODO
        });

        pon('tabswitched', function(d: Delta<PlayerTab>) {
            //TODO
        });
    }

	/**
	  * detach the current renderer from [this] view, and deallocate its memory
	  */
	public function detachRenderer(done: VoidCb):Void {
	    vsequence(function(step, exec) {
            // if [this] view even has media
            if (currentMediaRenderer != null) {
                // alert the renderer that it is being detached
                step(next -> currentMediaRenderer.onDetached(this, function(?error) {
                    if (error != null) {
                        report( error );
                    }
                    next( error );
                }));

                // deallocate that media
                step(next -> currentMediaRenderer.dispose(next));

                // handle synchronous tasks
                step((function() {
                    // unlink it from [this] Object
                    currentMediaRenderer = null;

                }).toAsync());
            }

            exec();
        }, done);
	}

	/**
	  * attach the given renderer to [this] view
	  */
	public function attachRenderer(mr:MediaRenderer, done:VoidCb):Void {
	    vsequence(function(step, exec) {
            // if [mr] isn't already attached to [this] view
            if (mr != currentMediaRenderer) {
                // if [this] view already has an attached renderer
                if (currentMediaRenderer != null) {
                    // unlink it
                    step( detachRenderer );
                }

                step(function(_) {
                    // now link the new one
                    currentMediaRenderer = mr;
                    currentMediaRenderer.onAttached(this, function(?error) {
                        if (error != null) {
                            return _(error);
                        }
                        
                        _();
                    });
                });
            }

            defer(exec.void());
        }, done);
	}

/* === Gryffin Methods === */

	/**
	  * Update [this]
	  */
	override function update(stage : Stage):Void {
		player.tick();

        // save current rects
        lastRect = new Pair(rect.clone(), (mediaRect != null ? mediaRect.clone() : null));

        // update things
		super.update( stage );

		// recalculate geometry
		calculateGeometry(stage.rect.float());

		// determine whether any resizing has occurred
		if (!rect.equals( lastRect.left )) {
		    var delta:Delta<Rect<Float>> = new Delta(rect, lastRect.left);
		    dispatch('resize', delta);
		}
        else if (mediaRect != null && !mediaRect.equals( lastRect.right )) {
            var delta:Delta<Rect<Float>> = new Delta(mediaRect, lastRect.right);
            dispatch('resize:media', delta);
        }

		// echo the playback properties onto the current media
		if (cmr != null) {
            cmr.update( stage );
		}
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
	override function calculateGeometry(r : Rect<Float>):Void {
		if ( !player.isReady )
		    return ;

		rect.pull( r );

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
            menu.popup({
                x: p.x,
                y: p.y
            });
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
	public var mediaRect : Rect<Float>;

	public var currentMediaRenderer : Null<MediaRenderer>;

	private var lastStatus : Null<PlayerStatus> = null;
	private var lastRect : Null<Pair<Rect<Float>, Rect<Float>>> = null;
}
