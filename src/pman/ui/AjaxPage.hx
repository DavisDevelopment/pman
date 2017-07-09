package pman.ui;

import tannus.io.*;
import tannus.ds.*;
import tannus.html.Element;
import tannus.sys.FileSystem as Fs;

import crayon.*;
import foundation.*;

import gryffin.core.*;
import gryffin.display.*;

import electron.ext.*;
import electron.ext.Dialog;

import pman.core.*;
import pman.media.*;
import pman.db.*;

import js.jquery.JqXHR;

import Std.*;
import electron.Tools.*;
import pman.Globals.*;

using StringTools;
using Lambda;
using Slambda;

class AjaxPage extends Page {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    /**
      *
      */
    override function populate():Void {
        // load content at [contentSrc] into [this.el] via ajax
        el.load(contentSrc, null, function(responseText:String, status:String, xhr:JqXHR) {
            // handle failed loading..
            if (status.toLowerCase() != 'success') {
                loadFailed(responseText, status, xhr);
            }
            else {
                // ensure proper asynchronicy by deferal onto next JavaScript stack
                defer(function() {
                    // perform post-load stuff
                    contentLoaded();
                });
            }
        });
    }

    /**
      * handle failure to load
      */
    private function loadFailed(responseText:String, statusText:String, xhr:JqXHR):Void {
        trace('oh yai, dat\'s hard on me, yeah sha');
    }

    /**
      * ajax content has been loaded in, but now must be linked to and/or manipulated
      */
    private function contentLoaded():Void {
        //TODO further organize this
    }

    private inline function e(x : Dynamic):Element return new Element( x );

/* === Instance Fields === */

    public var contentSrc:String;
}
