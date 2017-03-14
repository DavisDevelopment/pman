package pman.db;

import tannus.io.*;
import tannus.ds.*;
import tannus.ds.promises.*;

import ida.*;
import ida.backend.idb.IDBCursorWalker in CursorWalker;

import pman.core.*;
import pman.media.*;
import pman.db.MediaStore;

import js.Browser.console;
import Slambda.fn;
import tannus.math.TMath.*;
import electron.Tools.defer;
import haxe.extern.EitherType;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

class MediaItem {
    /* Constructor Function */
    public function new(store:MediaStore, row:MediaItemRow):Void {
        this.store = store;
        this.row = row;
        if (row.id == null) {
            throw 'Error: Cannot build Model around unsaved row';
        }

        id = row.id;
        uri = row.uri;
        _i = null;
    }

/* === Instance Methods === */

    /**
      * retrieve [this] media's info row
      */
    private function _loadInfo():Promise<MediaInfo> {
        return store.getMediaInfoRow( id ).transform.fn(new MediaInfo(store, this, _));
    }

    /**
      * get [this] Model's info
      */
    public function getInfo(cb : MediaInfo->Void):Void {
        if (_i != null) {
            defer(cb.bind( _i ));
        }
        else {
            if ( !_wi ) {
                var ip = _loadInfo();
                _wi = true;
                ip.then(function(info : Null<MediaInfo>) {
                    _wi = false;
                    _i = info;
                    getInfo( cb );
                });
                ip.unless(function(error : Null<Dynamic>) {
                    trace('Error: $error');
                });
            }
            else {
                defer(function() {
                    getInfo( cb );
                });
            }
        }
    }

/* === Instance Fields === */

    public var id : Int;
    public var uri : String;

    public var store : MediaStore;
    public var row   : MediaItemRow;

    private var _i : Null<MediaInfo>;
    private var _wi : Bool = false;
}
