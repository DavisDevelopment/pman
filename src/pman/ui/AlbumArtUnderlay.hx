package pman.ui;

import tannus.ds.*;
import tannus.io.*;
import tannus.geom.*;
import tannus.html.Element;
import tannus.events.*;

import crayon.*;

import gryffin.core.*;
import gryffin.display.*;

import foundation.*;

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

class AlbumArtUnderlay extends CanvasUnderlay {
    /* Constructor Function */
    public function new(art : gryffin.display.Image):Void {
        super();


        image = new Image( art.src );
        append( image );

        var c = image.css;
        c['width'] = '100%';
        c['height'] = '100%';

        addClass('unselectable');
        image.addClass('unselectable');
    }

/* === Instance Fields === */

    public var image : Image;
}
