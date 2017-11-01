package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.media.*;

import tannus.math.TMath.*;
import foundation.Tools.*;
import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class PlaylistChooserWidget extends Ent {
    /* Constructor Function */
    public function new(btn : TrackAddToPlaylistButton):Void {
        super();

        this.button = btn;
        items = new Array();
        _ic = new Dict();

        on('click', onClick);
    }

/* === Instance Methods === */

    override function init(stage : Stage):Void {
        super.init( stage );
    }

    override function render(stage:Stage, c:Ctx):Void {
        if (!button.controls.uiEnabled)
            return ;

        c.save();
        c.beginPath();
        c.fillStyle = theme.primary.lighten( 22 );
        c.drawRect( rect );
        c.fill();
        
        for (i in items) {
            i.render(stage, c);
        }
        c.restore();
    }

    override function update(stage : Stage):Void {
        super.update( stage );

        var mp = stage.getMousePosition();
        hovered = (mp != null && containsPoint( mp ));
        var hoveredItem:Null<PlaylistChooserItem> = null;
        if ( hovered ) {
            for (i in items) {
                i.hovered = false;
                if (mp.containedBy(x, i.y, w, i.h)) {
                    i.hovered = true;
                    hoveredItem = i;
                }
            }
            stage.cursor = 'default';
            if (hoveredItem != null) {
                stage.cursor = 'pointer';
            }
        }

        centerY = button.centerY;
        x = (button.x + button.w + 10);
        positionItems( stage );
    }

    /**
      * calculate the positions of the items
      */
    private function positionItems(stage : Stage):Void {
        var ip:Point = new Point((x), (y));

        w = 0.0;
        for (i in items) {
            i.update( stage );
            var iw = i.w;
            w = max(w, iw);
        }
        w += 10.0;

        for (i in items) {
            i.centerX = centerX;
            i.y = ip.y;

            ip.y += (i.h);
        }

        h = (ip.y - y);
    }

    /**
      * promise
      */
    public function open():Promise<Maybe<String>> {
        return Promise.create({
            show();
            once('addedto', function(name) {
                return name;
            });
            once('cancelled', untyped function() {
                return null;
            });
        });
    }

    /**
      * build [this] layout out
      */
    public function buildLayout():Void {
        var newPlaylistItem = new NewPlaylistItem( this );
        addItem( newPlaylistItem );
        var names = appDir.allSavedPlaylistNames();
        for (name in names) {
            var item = new PlaylistChooserItem(this, name);
            addItem( item );
        }
    }

    /**
      * dismantle the layout
      */
    public function clear():Void {
        for (name in _ic.keys()) {
            removeItem( name );
        }
    }

    /**
      * refresh [this] widget
      */
    public inline function refresh():Void {
        clear();
        buildLayout();
    }

    /**
      * add a PlaylistChooserItem to [this]
      */
    public function addItem(item : PlaylistChooserItem):Void {
        if (!hasItem( item.name )) {
            _ic[item.name] = item;
            items.push( item );
        }
    }

    /**
      * obtain an item by name
      */
    public inline function getItem(name : String):Maybe<PlaylistChooserItem> {
        return _ic[name];
    }

    /**
      * check whether [name] is attached to [this]
      */
    public inline function hasItem(name : String):Bool {
        return _ic.exists( name );
    }

    /**
      * remove an item from [this]
      */
    public function removeItem(name : String):Bool {
        var item = getItem( name );
        if (item != null) {
            items.remove( item );
            return _ic.remove( name );
        }
        else return false;
    }

    public function onClick(event : MouseEvent):Void {
        var p = event.position;
        if ( _hidden )
            return ;
        var i = getItemByPoint( p );
        if (i != null) {
            i.onClick( event );
        }
    }

    public function getItemByPoint(p : Point):Maybe<PlaylistChooserItem> {
        for (i in items) {
            if (p.containedBy(x, i.y, w, i.h)) {
                return i;
            }
        }
        return null;
    }

    public function cancelClick(event : MouseEvent):Void {
        if (!containsPoint( event.position )) {
            event.stopPropogation();
            hide();
            dispatch('cancelled', null);
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

/* === Instance Fields === */

    public var button : TrackAddToPlaylistButton;
    public var items : Array<PlaylistChooserItem>;
    public var hovered : Bool = false;

    private var _ic : Dict<String, PlaylistChooserItem>;
}

class PlaylistChooserItem extends Ent {
    public function new(chooser:PlaylistChooserWidget, name:String):Void {
        super();

        this.name = name;
        this.chooser = chooser;
        this.t = new TextBox();
        t.color = new Color(255, 255, 255);
        refresh();
    }

/* === Instance Methods === */

    /**
      * initialize [this]
      */
    override function init(stage : Stage):Void {

    }

    /**
      * update [this]
      */
    override function update(stage : Stage):Void {
        t.text = name;

        calculateGeometry( rect );
    }

    override function render(stage:Stage, c:Ctx):Void {
        c.drawComponent(t, 0, 0, t.width, t.height, x, y, t.width, t.height);
    }

    /**
      * calculate geometry
      */
    override function calculateGeometry(r : Rectangle):Void {
        w = (t.width);
        h = (t.height);
    }

    /**
      * refresh [this]'s data
      */
    public function refresh():Void {
        var l = appDir.playlists.readPlaylist( name );
        status = (player.track != null ? l.has( player.track ) : false);
        t.color = (status ? player.theme.secondary : new Color(255, 255, 255));
    }

    /**
      * when [this] gets clicked
      */
    public function onClick(event : MouseEvent):Void {
        function addTo(list: Playlist):Void {
            if (player.track != null) {
                if (!list.has( player.track )) {
                    list.push( player.track );
                }
            }
            
            status = true;
        }

        function complete(?error) {
            if (error != null) {
                report( error );
            }
            else {
                chooser.dispatch('addedto', name);
                chooser.hide();
            }
        }

        appDir.playlists.editSavedPlaylist(name, addTo, complete);
    }

/* === Instance Fields === */

    public var name : String;
    public var chooser : PlaylistChooserWidget;

    public var t : TextBox;
    public var status : Bool;
    public var hovered : Bool = false;
}

class NewPlaylistItem extends PlaylistChooserItem {
    public function new(chooser:PlaylistChooserWidget):Void {
        super(chooser, 'Create New Playlist');
    }

    override function onClick(event : MouseEvent):Void {
        player.prompt('Playlist Name', null, null, function(playlistName : Null<String>) {
            trace( playlistName );
            if (playlistName == null || playlistName == '') {
                chooser.dispatch('cancelled', null);
            }
            else {
                var list = new Playlist([player.track]);
                appDir.playlists.writePlaylist(playlistName, list);
                chooser.dispatch('addedto', playlistName);
            }
            chooser.hide();
        });
    }

    override function refresh():Void {
        return ;
    }
}
