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

class VideoUnderlay extends CanvasUnderlay {
    /* Constructor Function */
    public function new(video : Video):Void {
        super();

        addClass('unselectable');

        this.video = video;
        vel = new Element(@:privateAccess video.vid);
        append( vel );
        vel.style.write({
            'position': 'absolute',
            'left': '0px',
            'top': '0px',
            'min-width': '100%',
            'min-height': '100%',
            'width': 'auto',
            'height': 'auto'
        });
    }

/* === Instance Fields === */

    public var video : Video;
    public var vel : Element;
}
