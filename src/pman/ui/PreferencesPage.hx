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

using StringTools;
using Lambda;
using Slambda;

class PreferencesPage extends Page {
    /* Constructor Function */
    public function new(app : BPlayerMain):Void {
        super();

        addClass( 'prefeditor' );

        this.app = app;
    }

/* === Instance Methods === */

    /**
      * when [this] Page opens
      */
    override function open(body : Body):Void {
        super.open( body );

        el.load('preferences.html', null, function(responseText:String, status:String, xhr) {
            defer(function() {
                syncFields();
                trace( fields );
            });
        });
    }

    /**
      * obtain references to field-inputs
      */
    private function syncFields():Void {
        var df:Object = {};
        var names = ['autoPlay', 'autoRestore', 'directRender', 'showAlbumArt', 'showSnapshot', 'snapshotPath'];
        for (name in names) {
            df[name] = e('#$name');
        }
        this.fields = df;
    }

    private static inline function e(x : Dynamic):Element return new Element( x );

/* === Instance Fields === */

    private var app : BPlayerMain;
    private var fields : PFields;
}

private typedef PFields = {
    autoPlay : Element,
    autoRestore : Element,
    directRender : Element,
    showAlbumArt : Element,
    snapshotPath : Element
};
