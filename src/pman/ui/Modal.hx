package pman.ui;

import foundation.*;

import tannus.chrome.FileSystem;

import tannus.html.Element;
import tannus.ds.Memory;
import tannus.events.*;
import tannus.events.Key;

import pman.core.*;

import Std.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using tannus.math.TMath;

class Modal extends Pane {
    /* Constructor Function */
    public function new():Void {
        super();

        addClass( 'modal' );
    }

/* === Instance Methods === */

    public function open():Void {
        appendTo('body');
    }

    public function close():Void {
        destroy();
    }
}
