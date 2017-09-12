package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.Tools.*;
import electron.MenuTemplate;
import electron.ext.Menu;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.hud.*;
import pman.ui.tabs.*;
import pman.ui.statusbar.*;
import pman.media.Track;
import pman.events.DragDropEvent;
import pman.events.PlayerDragDropEvent;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

@:access( gryffin.core.EventDispatcher )
class DragDropWidget extends Ent {
    /* Constructor Function */
    public function new(view : PlayerView):Void {
        super();

        pv = view;
    }

/* === Instance Methods === */

    /**
      * initialize [this] widget
      */
    override function init(stage : Stage):Void {
        super.init( stage );

        bind_events();
    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        super.update( stage );
    }

    /**
      * render [this]
      */
    override function render(stage:Stage, c:Ctx):Void {
        if (dragInProgress && dp != null) {
            var droprect = new Rectangle(0, 0, 95, 95);
            droprect.center = dp;

            c.save();
            c.beginPath();
            c.lineWidth = 3.5;
            c.strokeStyle = 'limegreen';
            c.drawRect( droprect );
            c.closePath();
            c.stroke();
            c.restore();
        }
    }

    /**
      * calculate [this]'s geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        rect.cloneFrom( pv.rect );
    }

    /**
      * check whether the given Point is inside of [this]'s content rectangle
      */
    override function containsPoint(p : Point):Bool {
        return false;
    }

    /**
      * register event listeners
      */
    private function bind_events():Void {
        inline function s<T>(n) return player.sig( n );

        dragEnter = s('dragenter');
        dragLeave = s('dragleave');
        dragOver = s('dragover');
        dragEnd = s('dragend');
        drop = s('drop');

        monitorDrag();
    }

    /**
      * monitor drag-over events
      */
    private function monitorDrag():Void {
        function dragStep(e : PlayerDragDropEvent) {
            if ( dragInProgress ) {
                this.dp = e.playerPanePosition();
            }
        }
        dragOver.on( dragStep );

        function doda(b : Bool) {
            return function(e:PlayerDragDropEvent) {
                dragInProgress = b;
                if ( !dragInProgress )
                    dp = null;
            };
        }
        
        dragEnter.on(doda(true));
        dragLeave.on(doda(false));
        dragEnd.on(doda(false));

        inline function gb(n) return pv.controls.getButtonByName( n );

        var prevBtn = gb('previous');
        var nextBtn = gb('next');

        drop.on(function(event) {
            dragInProgress = false;
            dp = event.playerPanePosition();
            var specialCaseInvoked:Bool = false;
            var specop:Null<VoidAsync> = null;
            if (pv.controls.containsPoint( dp )) {
                if (prevBtn.containsPoint( dp )) {
                    //TODO
                }
                else if (nextBtn.containsPoint( dp )) {
                    specialCaseInvoked = true;
                    specop = function(done : VoidCb) {
                        playNextBatch( event.tracks );
                        done();
                    };
                }
            }
            if ( specialCaseInvoked ) {
                event.preventDefault();
                
                function specop_cb(?error : Dynamic) {
                    if (error != null) {
                        (untyped __js__('console.error'))( error );
                    }
                };

                (new VoidAsync(
                 if (specop == null)
                    specop = untyped (function(f:VoidCb) return f());
                 else
                    specop
                ))( specop_cb );
            }
        });
    }

    /**
      * queue a 'batch' of tracks to play after the current one
      */
    private function playNextBatch(list:Array<Track>) {
        var tracks = player.session.playlist.toArray();
        var index = tracks.indexOf( player.track );
        player.clearPlaylist();
        var hunks:Array<Array<Track>> = [
            tracks.slice(0, index),
            list,
            tracks.slice(index + 1)
        ];
        trace( hunks );
        var toAdd:Array<Track> = (hunks.flatten().array());
        player.addItemList( toAdd );
    }

/* === Computed Instance Fields === */

    public var player(get, never):Player;
    private inline function get_player() return pv.player;

/* === Instance Fields === */

    private var pv : PlayerView;
    private var dp : Null<Point> = null;
    private var dragInProgress : Bool = false;

    public var dragEnter : Signal<PlayerDragDropEvent>;
    public var dragLeave : Signal<PlayerDragDropEvent>;
    public var dragOver : Signal<PlayerDragDropEvent>;
    public var dragEnd : Signal<PlayerDragDropEvent>;
    public var drop : Signal<PlayerDragDropEvent>;
}