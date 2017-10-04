package pman.core.engine;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;
import tannus.sys.Path;
import tannus.sys.FileSystem as Fs;
import tannus.async.*;

import electron.ext.FileFilter;
import electron.ext.Dialog.FileDialogProperty;
import electron.ext.Dialog.FileOpenOptions;
import electron.ext.Dialog.FileDialogOptions;
import electron.ext.Dialog as D;

import pman.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;

class Dialogs {
    /* Constructor Function */
    public function new(e : Engine):Void {
        engine = e;
    }

/* === Instance Methods === */

    /**
      * prompt the user to select files to open
      */
    public function open(?opts:FSDialogOptions, ?done:Cb<Array<Path>>):Null<ArrayPromise<Path>> {
        var options = _convertOpen(_completeOpen(opts != null ? opts : {}));
        if (done == null) {
            return Promise.create({
                D.showOpenDialog(options, function( stringPaths ) {
                    if (stringPaths == null)
                        stringPaths = [];
                    var paths:Array<Path> = stringPaths.map.fn(Path.fromString(_));
                    return paths;
                });
            }).array();
        }
        else {
            D.showOpenDialog(options, function( stringPaths ) {
                if (stringPaths == null)
                    stringPaths = [];
                var paths:Array<Path> = stringPaths.map.fn(Path.fromString( _ ));
                done(null, paths);
            });
            return null;
        }
    }

    public function selectFile(?opts:FSDialogOptions, ?done:Cb<Path>):Null<Promise<Path>> {
        opts = _completeOpen(opts != null ? opts : {});
        opts.multiple = false;
        if (done == null) {
            return open( opts ).transform.fn(_[0]);
        }
        else {
            return untyped open(opts, function(?error, ?paths) {
                done(error, (if (paths != null) paths[0] else null));
            });
        }
    }

    public function selectFiles(?opts:FSDialogOptions, ?done:Cb<Array<Path>>):Null<ArrayPromise<Path>> {
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
	?directory: Bool
};
