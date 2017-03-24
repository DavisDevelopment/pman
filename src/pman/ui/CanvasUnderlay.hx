package pman.ui;

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
import pman.ui.pl.*;
import pman.search.SearchEngine.Match as SearchMatch;

using StringTools;
using Lambda;
using Slambda;

class CanvasUnderlay extends Pane {
    /* Constructor Function */
    public function new():Void {
        super();

        addClass('canvas-underlay');
    }

/* === Instance Methods === */

    /**
      * get [this]'s rectangle
      */
    public inline function getRect():Rectangle {
        return el.rectangle;
    }

    /**
      * set [this]'s rectangle
      */
    public function setRect(rect : Rectangle):Void {
        var c = css;
        inline function px(n : Float) return (n + 'px');

        c['left'] = px( rect.x );
        c['top'] = px( rect.y );
        c['width'] = px( rect.width );
        c['height'] = px( rect.height );
    }

/* === Computed Instance Fields === */

}
