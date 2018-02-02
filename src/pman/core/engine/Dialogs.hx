package pman.core.engine;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;
import tannus.async.promises.*;

import electron.ext.FileFilter;
import electron.ext.Dialog.FileDialogProperty;
import electron.ext.Dialog.FileOpenOptions;
import electron.ext.Dialog.FileDialogOptions;
import electron.ext.Dialog as D;

import js.html.Notification;
import js.html.NotificationPermission;
//import js.html.NotificationOptions;

import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.async.Asyncs;
using pman.bg.URITools;

class Dialogs {
    /* Constructor Function */
    public function new(e : Engine):Void {
        engine = e;
    }

/* === Instance Methods === */

    /**
      * prompt the user to select files to open
      */
    public function open(?opts:FSDialogOptions, ?done:Cb<Array<Path>>):ArrayPromise<Path> {
        var options:FileOpenOptions = _convertOpen(_completeOpen(opts != null ? opts : {}));
        return Promise.create({
            D.showOpenDialog(options, function( stringPaths ) {
                if (stringPaths == null)
                    stringPaths = [];
                var paths:Array<Path> = stringPaths.compact().map.fn(Path.fromString(_));
                if (!paths.empty()) {
                    var first:Path = paths[0];
                    while (!Fs.isDirectory( first ))
                        first = first.directory;

                    if (first.toString().hasContent()) {
                        engine.db.configInfo.lastDirectory = first;
                    }
                }
                return paths;
            });
        }).toAsync( done ).array();
    }

    /**
	  * create and display a FileSystem 'save' dialog
	  */
	public function save(?opts:FSDialogOptions, ?done:Cb<Path>):Promise<Null<Path>> {
	    if (opts == null) opts = {};
	    var options:FileOpenOptions = _convertOpen(_completeOpen( opts ));
	    return new Promise<Path>(function(accept, reject) {
            D.showSaveDialog(options, function(name : Null<String>) {
                var path:Null<Path> = (name != null ? new Path( name ) : null);
                return accept( path );
            });
        });
	}

    /**
      * create a notification and display it to the user
      */
	public function notify(title:String, ?options:NotifyOptions):Promise<Null<Notification>> {
	    inline function requestPermission():js.Promise<NotificationPermission> {
	        return (untyped __js__('{0}.requestPermission', Notification)());
	    }
	    return new Promise<Null<Notification>>(function(yes, no) {
	        function _handlePermission(perm: NotificationPermission) {
                switch ( perm ) {
                    case NotificationPermission.DEFAULT_:
                        requestPermission().then(function(nperm: NotificationPermission) {
                            _handlePermission( nperm );
                        }, no);

                    case NotificationPermission.DENIED:
                        // user does not want notifications
                        yes( null );

                    case NotificationPermission.GRANTED:
                        if (options == null) options = {};
                        options = _completeNotify( options );
                        var note:Notification = new Notification(title, untyped options);
                        yes( note );

                    case anythingElse:
                        no('Error: "$anythingElse" is not a NotificationPermission');
                }
            }
            //
            _handlePermission( Notification.permission );
	    });
	}

    /**
      * prompt the user to select a single file
      */
    public function selectFile(?opts:FSDialogOptions, ?done:Cb<Path>):Promise<Path> {
        opts = _completeOpen(opts != null ? opts : {});
        opts.multiple = false;
        return open( opts ).transform.fn(_[0]).toAsync( done );
    }

    /**
      * prompt the user to select one or more files
      */
    public function selectFiles(?opts:FSDialogOptions, ?done:Cb<Array<Path>>):ArrayPromise<Path> {
        opts = _completeOpen(opts != null ? opts : {});
        opts.multiple = true;
        return open(opts, done);
    }

    /**
      * convert a FSDialogOptions object to a FileDialogOptions object
      */
	private function _convertOpen(o : FSDialogOptions):FileOpenOptions {
	    var fileOptions:Array<FileDialogProperty> = [OpenFile];
	    if (o.multiple == null || o.multiple) {
	        fileOptions.push( MultiSelections );
	    }
		var res:FileOpenOptions = {
			title: o.title,
			buttonLabel: o.buttonLabel,
			defaultPath: o.defaultPath,
			filters: o.filters,
			properties: (o.directory ? [OpenDirectory] : fileOptions)
		};
		if (res.defaultPath == null) {
		    res.defaultPath = database.configInfo.lastDirectory;
		}
		return res;
	}

    /**
	  * fill in missing fields on FSPromptOptions
	  */
	private function _completeOpen(o : FSDialogOptions):FSDialogOptions {
		if (o.directory == null)
			o.directory = false;
		if (o.title == null)
			o.title = 'PMan FileSystem Prompt';
		if (o.multiple == null)
		    o.multiple = true;
		if (o.defaultPath == null && engine.db.configInfo.lastDirectory != null)
		    o.defaultPath = engine.db.configInfo.lastDirectory.toString();
		return o;
	}

	/**
	  * fill in missing fields on NotifyOptions object
	  */
	private function _completeNotify(o : NotifyOptions):NotifyOptions {
	    var assets:Path = engine.appDir.appPath('assets/');
	    inline function uri(s: String):String return assets.plusString( s ).toUri();

	    if (o.badge == null) {
	        o.badge = uri('icon64.png');
	    }

	    if (o.icon == null) {
	        o.icon = uri('icon64.png');
	    }

	    return o;
	}

/* === Instance Fields === */

    private var engine : Engine;
}

typedef FSDialogOptions = {
	?title: String,
	?defaultPath: String,
	?buttonLabel: String,
	?filters: Array<FileFilter>,
	?multiple: Bool,
	?directory: Bool,
	?complete: Null<Path> -> Void
};

typedef NotifyOptions = {
    ?body: String,
    ?data: Dynamic,
    ?badge: String,
    ?icon: String,
    ?image: String,
    ?tag: String,
    ?requireInteraction: Bool
};
