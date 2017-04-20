package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.Shell;

import pman.core.*;
import pman.media.*;
import pman.db.*;
import pman.db.MediaStore;
import pman.async.*;

import Std.*;
import tannus.math.TMath.*;
import electron.Tools.defer;
import Slambda.fn;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

class CleanDatabase extends Task1 {
    private var db : PManDatabase;
    public function new(db : PManDatabase):Void {
        super();

        this.db = db;
    }

    /**
      * execute [this] task
      */
    override function execute(done : VoidCb):Void {
        var store = db.mediaStore;
        var ids:Array<Int> = new Array();
        var tr = store.db.transaction('media_items', 'readwrite');
        function onWalkOver(error:Null<Dynamic>) {
            if (error != null)
                done( error );
            else {
                //TODO
                clean(ids, done);
            }
        }
        function _step(row : MediaItemRow):Void {
            ids.push( row.id );
        };
        store.walk('media_items', _step, tr, test, onWalkOver);
    }

    /**
      * delete database entries referenced by [ids]
      */
    private function clean(ids:Array<Int>, done:VoidCb):Void {
        [clean_media_items.bind(ids), clean_media_info.bind(ids)].series( done );
    }

    /**
      * delete rows from 'media_items'
      */
    private function clean_media_items(ids:Array<Int>, done:VoidCb):Void {
        var deletes = ids.map.fn(id => db.mediaStore.deleteFrom.bind('media_items', id, _));
        deletes.callEach( done );
    }

    /**
      * delete rows from 'media_info'
      */
    private function clean_media_info(ids:Array<Int>, done:VoidCb):Void {
        var deletes = ids.map.fn(id => db.mediaStore.deleteFrom.bind('media_info', id, _));
        deletes.callEach( done );
    }

    /**
      * check that [row] is not referencing assets that no longer exist
      */
    private function test(row : MediaItemRow):Bool {
        var p = getPath( row.uri );
        if (p == null)
            return false;
        else {
            return !FileSystem.exists( p );
        }
    }

    /**
      * get a filesystem path from a uri
      */
    private function getPath(uri : String):Maybe<Path> {
        return switch (uri.uriToMediaSource()) {
            case MediaSource.MSLocalPath(path): path;
            default: null;
        };
    }
}
