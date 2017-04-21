package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.node.Fs as Nfs;

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

class ExportDatabase extends Task1 {
    /* Constructor Function */
    public function new(db:PManDatabase, ?output:Path):Void {
        super();

        this.db = db;
        this.output = null;
        this.data = {};
    }

/* === Instance Methods === */

    override function execute(done : VoidCb):Void {
        var actions = [get_path, pull_tags, pull_media, write_data];
        actions.series( done );
    }

    private function write_data(done : VoidCb):Void {
        try {
            var sdata:String = haxe.Json.stringify(data.toDyn());
            Nfs.writeFileSync(output, sdata);
            done();
        }
        catch (error : Dynamic) {
            done( error );
        }
    }

    private function get_path(done : VoidCb):Void {
        if (output != null)
            return done();
        BPlayerMain.instance.fileSystemSavePrompt(null, function(path:Null<Path>) {
            output = path;
            if (output == null)
                return done('user cancelled');
            else done();
        });
    }

    private function pull_tags(done : VoidCb):Void {
        db.tagsStore.getAllTagRows_(function(?err, ?rows) {
            if (err != null)
                done( err );
            var tags:Array<String> = rows.map.fn(_.name);
            data['tags'] = tags;
            trace( tags );
            done();
        });
    }

    private function pull_media(done : VoidCb):Void {
        var tags:Array<String> = data['tags'];
        db.mediaStore.getAllMediaItemRows_(function(?err, ?rows) {
            if (err != null)
                done( err );
            else {
                var medias:Array<Object> = new Array();
                function load(m:MediaItemRow, cb:VoidCb) {
                    db.mediaStore.getMediaInfoRow_(m.id, function(?e, ?mi) {
                        if (e != null)
                            cb( e );
                        else {
                            var entry:Object = new Object( mi );
                            entry['uri'] = m.uri;
                            medias.push( entry );
                            cb();
                        }
                    });
                };
                var loads:Array<VoidAsync> = rows.map.fn(row=>load.bind(row, _));
                loads.callEach(function(?error) {
                    if (error != null)
                        done( error );
                    else {
                        data['media'] = medias;
                        done();
                    }
                });
            }
        });
    }

/* === Instance Fields === */

    public var db : PManDatabase;
    public var output : Null<Path>;
    public var data : Obj;
}
