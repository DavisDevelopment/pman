package pman.ui.pl;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import electron.Tools.*;

import pman.core.*;
import pman.media.*;
import pman.media.PlaylistChange;

using StringTools;
using Lambda;
using Slambda;

class TrackListView extends Row {
    /* Constructor Function */
    public function new():Void {
        super();

        addClass('trackList');
        
        tracks = new Array();
        list = null;
    }

/* === Instance Methods === */

    /**
      * build the list
      */
    private function buildList():Void {
        list = new List();
        append( list );
        list.el.plugin('disableSelection');
        bindList();
    }

    /**
      * bind events to the List
      */
    private function bindList():Void {
        //TODO
        if (list != null) {
            list.forwardEvents(['mousemove', 'mouseleave', 'mouseenter'], null, MouseEvent.fromJqEvent);
        }

        var sortOptions = {
            update: function(event, ui) {
                var item:Element = ui.item;
                var t:TrackView = item.children().data( 'view' );
                //playlist.move(t.track, (function() return getIndexOf( t )));
            }
        };
        list.el.plugin('sortable', [sortOptions]);
    }

    /**
      * get the index of the given TrackView
      */
    public function getIndexOf(tv : TrackView):Int {
        var lis:Element = new Element(list.el.children());
        for (index in 0...lis.length) {
            var li:Element = new Element(lis.at( index ));
            var view:Null<TrackView> = li.children().data('view');
            if (view != null && Std.is(view, TrackView) && view == t) {
                return index;
            } 
        }
        return -1;
    }

/* === Instance Fields === */

    public var tracks : Array<TrackView>;
    public var list : Null<List>;
}
