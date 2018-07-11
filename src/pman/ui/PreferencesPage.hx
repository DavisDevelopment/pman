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
import pman.edb.*;

import Std.*;
//import electron.Tools.*;
import edis.Globals.*;
import pman.Globals.*;

using StringTools;
using Slambda;
using tannus.async.Asyncs;

class PreferencesPage extends Page {
    /* Constructor Function */
    public function new(app : BPlayerMain):Void {
        super();

        addClass( 'ui_page' );
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

                e('#cancel').click(function(ev) {
                    back();
                });

                e('#save').click(function(ev) {
                    //var p = app.db.preferences;
                    appState.lock();
                    appState.playback.autoPlay = fields.autoPlay.prop('checked');
                    appState.sessMan.autoRestoreSession = fields.autoRestore.prop('checked');
                    appState.rendering.directRender = fields.directRender.prop('checked');
                    appState.player.showAlbumArt = fields.showAlbumArt.prop('checked');
                    appState.player.showSnapshot = fields.showSnapshot.prop('checked');
                    appState.unlock();
                    function done_saving(?error) {
                        if (error != null) {
                            report( error );
                            back();
                        }
                        else {
                            back();
                        }
                    }
                    appState.save(null, null).toAsync(done_saving);
                });
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

        fields.autoPlay.prop('checked', appState.playback.autoPlay);
        fields.autoRestore.prop('checked', appState.sessMan.autoRestoreSession);
        fields.directRender.prop('checked', appState.rendering.directRender);
        fields.showAlbumArt.prop('checked', appState.player.showAlbumArt);
        fields.showSnapshot.prop('checked', appState.player.showSnapshot);
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
    showSnapshot : Element,
    snapshotPath : Element
};
