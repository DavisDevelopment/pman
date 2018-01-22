package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.core.exec.BatchExecutor;
import pman.bg.media.*;
import pman.bg.media.MediaData;
import pman.media.*;
import pman.edb.*;
import pman.bg.db.*;
import pman.async.*;

import haxe.Serializer;
import haxe.Unserializer;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.core.ExecutorTools;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;
using pman.bg.DictTools;

@:access( pman.media.Track )
class EfficientTrackListDataLoader extends Task1 {
    /* Constructor Function */
    public function new(tracks:Array<Track>, ms:MediaStore):Void {
        super();

        this.tracks = tracks;
        this.db = PManDatabase.get();
        this.missingData = new Array();
        this.treg = new Dict();
        this.writes = new Array(); 
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : VoidCb):Void {
        trace('Starting EfficientTrackListDataLoader');
        var uris:Array<String> = new Array();
        for (track in tracks) {
            uris.push( track.uri );
            treg[track.uri] = track;
        }

        function complete(?error : Dynamic) {
            var end = now();
            var took = (end - startTime);
            trace('EfficientTrackListDataLoader loaded data for ${tracks.length} in ${took}ms');
            done( error );
        }

        var rlp = db.media.getRowsByUris( uris );
        rlp.then(function( rows ) {
            trace('Loaded ${rows.length} documents from database in ${now() - startTime}ms');
            process_existing_rows(rows, complete);
        });
        rlp.unless(function( error ) {
            complete( error );
        });
    }

    /**
      * process and handle the rows loaded for the Tracks who already have data in the database
      */
    private function process_existing_rows(rows:Array<MediaRow>, done:VoidCb):Void {
        var subs:Array<VoidAsync> = new Array();
        cache = new TrackBatchCache( db );

        var stupidTracks = new List();
        for (track in tracks) {
            stupidTracks.add( track );
        }

        var track: Track;
        var data: TrackData;
        for (row in rows) {
            track = treg[row.uri];
            data = new TrackData( track );

            subs.push(function(next : VoidCb) {
                process_existing_row(track, data, row, function(?error) {
                    if (error != null)
                        report( error );
                    next( error );
                });
            });
            stupidTracks.remove( track );
        }

        subs.series(function(?error) {
            if (error != null) {
                return done( error );
            }
            else {
                missingData = stupidTracks.array();
                [
                    perform_writes,
                    create_missing_track_data,
                    update_views
                ].series( done );
            }
        });
    }

    /**
      * perform database-writes
      */
    private function perform_writes(done : VoidCb):Void {
        //writes.start(function() {
            //done();
        //});
        writes.series( done );
    }

    /**
      * update the views for all Tracks
      */
    private function update_views(done : VoidCb):Void {
        defer(function() {
            if (tracks.length < 50) {
                for (t in tracks)
                    t.updateView();
            }
            else {
                var gf = ((t:Track) -> t.updateView.bind());
                var ca = ((a:Array<Void->Void>) -> a.iter.fn(_()));
                for (ta in tracks.chunk( 5 )) {
                    ca(ta.map( gf ));
                }
            }
            done();
        });
    }

    /**
      * create new TrackData for those Tracks that were missing theirs
      */
    private function create_missing_track_data(done : VoidCb):Void {
        var creates = new Array();
        var pushes = new Array();

        for (track in missingData) {
            if ( !track._loadingData ) {
                creates.push(function(next : VoidCb) {
                    track._loadingData = true;
                    create_new_data(track, pushes, function(?error, ?data:TrackData) {
                        track._loadingData = false;
                        if (error != null) {
                            next( error );
                        }
                        else {
                            track.data = data;
                            next();
                            track._dataLoaded.call( data );
                        }
                    });
                });
            }
        }

        var cpb = exec.createBatch();
        for (create in creates)
            cpb.asyncTask(cast create);

        for (push in pushes)
            cpb.asyncTask(cast push);

        cpb.start(function() {
            done();
        });
        //[creates.series, pushes.series].series( done );
    }

    /**
      * create new TrackData for the given Track
      */
    private function create_new_data(track:Track, pushes:Array<VoidAsync>, submit:Cb<TrackData>):Void {
        data = new TrackData( track );
        load_media_metadata(track, function(?error, ?meta) {
            if (error != null) {
                return submit(error, null);
            }
            else {
                data.meta = meta;
                pushes.push(push_new_data_to_db.bind(data, _));
                return submit(null, data);
            }
        });
    }

    /**
      * push some data to the database
      */
    private function push_new_data_to_db(data:TrackData, done:VoidCb):Void {
        var raw:MediaRow = data.toRaw();
        this.data = data;
        
        // function to perform a basic INSERT operation
        function insert(done : VoidCb) {
            db.media.insertRow(raw, function(?error, ?row:MediaRow) {
                if (error != null) {
                    return done( error );
                }
                else {
                    return pull_raw(row, data, function(?error) {
                        if (error != null) {
                            done( error );
                        }
                        else {
                            data.track.mediaId = data.media_id;
                            done();
                        }
                    });
                }
            });
        }

        // function to handle errors in the push operation
        function handle_error(error : Dynamic):Void {
            done( error );
        }

        insert(function(?error) {
            if (error != null) {
                handle_error( error );
            }
            else {
                done();
            }
        });
    }

    /**
      * get the media metadata for the given Track
      */
    private function load_media_metadata(track:Track, done:Cb<MediaMetadata>):Void {
        track.source.getMediaMetadata().toAsync( done );
    }

    /**
      * process a single pre-existing row
      */
    private function process_existing_row(track:Track, data:TrackData, row:MediaRow, next:VoidCb):Void {
        track._loadingData = true;
        track.data = data;

        animFrame(function() {
            var steps = new Array();
            steps.push(function(nxt:VoidCb) {
                pull_raw(row, data, function(?error) {
                    if (error != null) {
                        nxt( error );
                    }
                    else {
                        ensure_track_data_completeness(data, function(?error) {
                            track._loadingData = false;
                            if (error != null) {
                                return nxt( error );
                            }
                            else {
                                nxt();
                                track._dataLoaded.call( data );
                            }
                        });
                    }
                });
            });
            steps.push(data.initialize.bind(db, _));
            VoidAsyncs.series(steps, next);
        });
    }

    /**
      * check that the given TrackData has all expected data, and if not, fill it in
      */
    private function ensure_track_data_completeness(data:TrackData, next:VoidCb):Void {
        var steps:Array<VoidAsync> = new Array();

        steps.push(function(nxt) {
            if (data.meta == null || data.meta.isIncomplete()) {
                load_media_metadata(data.track, function(?error, ?meta) {
                    if (error != null)
                        return nxt( error );
                    else if (meta != null) {
                        data.meta = meta;
                        
                        nxt();
                    }
                    else {
                        nxt('Error: Failed to load MediaMetadata');
                    }
                });
            }
            else {
                nxt();
            }
        });

        steps.push(patch_data.bind(data, _));
        steps.push(autofill_data.bind(data, _));

        steps.series( next );
    }

/* === Utility Methods === */

    /**
      * wrapper for TrackData.pullRaw
      */
    private function pull_raw(row:MediaRow, data:TrackData, done:VoidCb) {
        cache.get().unless(done.raise()).then(function(info) {
            data.pullRaw(row, done, db, info);
        });
    }

    /**
      * check that the given TrackData is complete
      */
    private function data_is_complete(data : TrackData):Bool {
        return true;
    }

    /**
      * patch the given TrackData
      */
    private function patch_data(data:TrackData, done:VoidCb):Void {
        //TODO
        done();
    }

    /**
      * automatically fill in data where possible
      */
    private function autofill_data(data:TrackData, done:VoidCb):Void {
        var autoFiller = new TrackDataAutoFill(data.track, data);
        autoFiller.giveCache( cache );
        autoFiller.run(function(?error) {
            if (error != null) {
                return done( error );
            }
            else {
                schedule_data_write( data );
                done();
            }
        });
    }

    /**
      * queue up the saving of the given TrackData
      */
    private function schedule_data_write(data : TrackData):Void {
        //writes.task(@async {
            //data.save(next, db);
        //});
        writes.push(data.save.bind(_, db));
    }

/* === Instance Fields === */

    private var tracks : Array<Track>;
    private var db: PManDatabase;
    private var missingData : Array<Track>;
    private var treg : Dict<String, Track>;
    //private var writes : BatchExecutor;
    private var writes: Array<VoidAsync>;

    private var track: Null<Track>;
    private var data: Null<TrackData>;
    private var cache: TrackBatchCache;
}
