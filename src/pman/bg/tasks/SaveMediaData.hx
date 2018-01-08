package pman.bg.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;
import tannus.async.promises.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.sys.FileSystem as Fs;

import ffmpeg.Fluent;

import pman.bg.Dirs;
import pman.bg.db.*;
import pman.bg.media.*;
import pman.bg.media.Media;
import pman.bg.media.MediaData;
import pman.bg.media.MediaRow;

import Slambda.fn;
import edis.Globals.*;

using StringTools;
using tannus.ds.StringUtils;
using Slambda;
using tannus.ds.ArrayTools;
using tannus.FunctionTools;
using tannus.async.Asyncs;
using pman.bg.MediaTools;

class SaveMediaData extends Task1 {
    private var data: MediaData;
    private var mrow: Null<MediaRow> = null;

    public function new(data: MediaData):Void {
        super();

        this.data = data;
    }

    public function save(?done: Cb<MediaRow>):Promise<MediaRow> {
        return Promise.create({
        run(function(?error) {
            if (error != null) {
                throw error;
            }
            else {
                return mrow;
            }
        });
        }).toAsync( done );
    }

    override function execute(done: VoidCb):Void {
        Database.get(function(db) {
            [
                get_mrow,
                push_tags,
                push_actors,
                push_marks,
                push_row
            ]
            .map(f -> f.bind(db))
            .series( done );
        });
    }

    private function get_mrow(db:Database, done:VoidCb):Void {
        db.media.cogRow(data.mediaUri, function(?error, ?row) {
            if (error != null) {
                done( error );
            }
            else {
                this.mrow = row;
                done();
            }
        });
    }

    private function push_tags(db:Database, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        db.tags.cogRows(data.tags, function(?error, ?rows) {
            if (error != null) {
                done( error );
            }
            else {
                data.tags = rows.map.fn( _.name );
                done();
            }
        });
    }

    private function push_actors(db:Database, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        if (data.actors.empty()) {
            return done();
        }
        else {
            var _actors = [];
            for (actor in data.actors) {
                steps.push(function(next) {
                    db.actors.cogActor(actor.name, function(?error, ?row) {
                        if (error != null) {
                            next( error );
                        }
                        else {
                            _actors.push( row );
                            next();
                        }
                    });
                });
            }
            steps.series(function(?error) {
                if (error != null) {
                    done( error );
                }
                else {
                    data.actors = _actors;
                    done();
                }
            });
        }
    }

    private function push_marks(db:Database, done:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();
        for (mark in data.marks) {
            //TODO
            steps.push(function(next) {
                //TODO
                next();
            });
        }
        steps.series( done );
    }

    private function push_row(db:Database, done:VoidCb):Void {
        if (mrow == null) {
            done('Error: [mrow] is null');
        }

        mrow.data = data.toRow();
        
        db.media.putRow(mrow, function(?error, ?newRow) {
            if (error != null) {
                done( error );
            }
            else {
                mrow = newRow;
                pull_new_row( done );
            }
        });
    }

    private function pull_new_row(done: VoidCb):Void {
        data.pullMediaRow(mrow, done);
    }
}
