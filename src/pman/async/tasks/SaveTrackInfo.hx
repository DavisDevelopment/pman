package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import electron.Shell;

import pman.core.*;
import pman.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.async.*;
import pman.media.info.*;
import edis.Globals.*;
import pman.Globals.*;

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

class SaveTrackInfo extends Task1 {
    /* Constructor Function */
    public function new(track:Track, delta:TrackInfoFormValueDelta):Void {
        super();

        this.track = track;
        this.delta = delta;
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : VoidCb):Void {
        [
            ensure_full_data,
            rename_track,
            save_data
        ].series( done );
    }

    /**
      ensure that the TrackData can be worked with
     **/
    private function ensure_full_data(done: VoidCb):Void {
        track.fillData( done );
    }

    /**
      * rename the Track, if necessary
      */
    private function rename_track(done : VoidCb):Void {
        if (delta.title != null) {
            var newPath:Path = (track.getFsPath().directory.plusString( delta.title.current )).normalize();
            var renamer = new TrackRename(track, database.mediaStore, newPath);
            renamer.run( done );
        }
        else {
            done();
        }
    }

    /**
      * do the stuff
      */
    private function save_data(done : VoidCb):Void {
        track.editData(edit_data, done, true);
    }

    private function edit_data(data:TrackData2, done:VoidCb):Void {
        inline function has(name: String):Bool {
            return (
                Reflect.hasField(delta, name) &&
                ((Reflect.field(delta, name) : Delta<Dynamic>).with([cur, pre], (
                    (cur != null || pre != null) && (cur != pre)
                )))
            );
        }

        vsequence(function(add, exec) {
            /* atomic-value properties */
            add(function(next) {
                /* [channel] property */
                if (has( 'channel' ))
                    data.channel = delta.channel.current;

                /* [contentRating] property */
                if (has( 'contentRating' ))
                    data.contentRating = delta.contentRating.current;

                /* [rating] property */
                if (has( 'rating' ))
                    data.rating = delta.rating.current;

                /* [description] property */
                if (has( 'description' ))
                    data.description = delta.description.current;

                defer(next.void());
            });

            // handle tags
            add(function(end) {
                if (has('tags')) {
                    var newTags = delta.tags.current;
                    data.tags = new Array();
                    for (t in newTags) {
                        data.addTag( t );
                    }
                }
                end();
            });

            // handle Actors
            add(function(end) {
                if (has('actors')) {
                    if (delta.actors.current != null) {
                        var newActors = delta.actors.current;
                        data.writeActors(newActors, function(?error, ?al) {
                            end( error );
                        });
                    }
                    else {
                        end();
                    }
                }
                else {
                    end();
                }
            });

            exec();
        }, done);
    }

/* === Instance Fields === */

    public var track : Track;
    public var delta : TrackInfoFormValueDelta;
}

typedef TrackInfoFormValueDelta = {
    ?title: Delta<String>,
    ?description: Delta<String>,
    ?tags: Delta<Array<String>>,
    ?actors: Delta<Array<String>>,
    ?rating: Delta<Float>,
    ?contentRating: Delta<String>,
    ?channel: Delta<String>
};
