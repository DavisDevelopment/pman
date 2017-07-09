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

import Std.*;
import electron.Tools.*;
import pman.Globals.*;

using StringTools;
using Lambda;
using Slambda;

class PManBrowserPage extends AjaxPage {
    /* Constructor Function */
    public function new():Void {
        super();

        contentSrc = 'pman-page.html';
    }

/* === Instance Methods === */

    /**
      * when opened
      */
    override function open(body : Body):Void {
        super.open( body );

        build();
    }

    /**
      * respond to the successful loading of the content
      */
    override function contentLoaded():Void {
        var rcp = e(el.find('div.pm-container:first'));
        if (rcp.length <= 0) {
            throw 'Invalid pman-page content';
        }

        content_pane = new Pane();
        content_pane.el = rcp;

        header = e(el.find('.pm-header'));
    }

/* === Instance Fields === */

    public var header : Element;

    public var content_pane : Pane;
}
